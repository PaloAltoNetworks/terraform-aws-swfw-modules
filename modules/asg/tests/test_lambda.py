"""Behaviour tests for the ASG lifecycle Lambda.

Seams under test:
  1. `VMSeriesInterfaceScaling.create_interface_settings` - the `interfaces_config`
     environment variable (as rendered by `jsonencode` in main.tf) is normalised
     into per-interface settings.
  2. `VMSeriesInterfaceScaling.add_public_ip_to_eni` - observed through the calls
     made on the EC2 client.
  3. `VMSeriesInterfaceScaling.create_and_configure_new_network_interface` - proves
     settings from seam 1 reach seam 2.
"""
from json import dumps
from logging import getLogger

from pytest import fixture

from lambda_function_under_test import VMSeriesInterfaceScaling


class FakeEC2Client:
    """Stands in for the boto3 EC2 client - the AWS API is a system boundary.

    Records the keyword arguments of every call so tests can assert on the
    request that would have been sent to EC2.
    """

    def __init__(self):
        self.calls = []

    def _record(self, operation):
        def _call(**kwargs):
            self.calls.append((operation, kwargs))
            return {
                'allocate_address': {'AllocationId': 'eipalloc-test', 'PublicIp': '198.51.100.10'},
                'associate_address': {'AssociationId': 'eipassoc-test'},
                'create_network_interface': {'NetworkInterface': {'NetworkInterfaceId': 'eni-test'}},
                'attach_network_interface': {'AttachmentId': 'eni-attach-test'},
            }.get(operation, {})

        return _call

    def __getattr__(self, operation):
        return self._record(operation)

    def args_of(self, operation: str) -> dict:
        """Keyword arguments of the single call made to `operation`."""
        matching = [kwargs for called, kwargs in self.calls if called == operation]
        assert len(matching) == 1, f"expected exactly one {operation} call, got {len(matching)}"
        return matching[0]


@fixture
def interfaces_config(monkeypatch):
    """Set the `interfaces_config` env var the way main.tf renders it."""

    def _set(interfaces: dict):
        monkeypatch.setenv("interfaces_config", dumps(interfaces))

    return _set


@fixture
def ec2():
    return FakeEC2Client()


@fixture
def scaling(ec2, monkeypatch):
    """A VMSeriesInterfaceScaling wired to a fake EC2 client.

    The constructor both builds boto3 clients and runs the lifecycle action, so
    the instance is created without it and the boundary client is injected.
    """
    monkeypatch.setenv("lambda_config", dumps({"region": "us-east-1", "tags": {"Name": "test"}}))
    instance = VMSeriesInterfaceScaling.__new__(VMSeriesInterfaceScaling)
    instance.logger = getLogger("test")
    instance.ec2_client = ec2
    return instance


def test_interface_settings_carry_the_public_ipv4_pool(interfaces_config):
    interfaces_config({
        "untrust": {
            "device_index": 2,
            "subnet_id": {"us-east-1a": "subnet-untrust-a"},
            "create_public_ip": True,
            "public_ipv4_pool": "ipv4pool-ec2-0123456789abcdef0",
            "security_group_ids": ["sg-untrust"],
            "source_dest_check": False,
        }
    })

    settings = VMSeriesInterfaceScaling.create_interface_settings("us-east-1a")

    assert settings[0]["pub_pool"] == "ipv4pool-ec2-0123456789abcdef0"


def test_eip_is_allocated_from_the_given_public_ipv4_pool(scaling, ec2):
    scaling.add_public_ip_to_eni("eni-untrust", "ipv4pool-ec2-0123456789abcdef0")

    assert ec2.args_of("allocate_address") == {
        "Domain": "vpc",
        "PublicIpv4Pool": "ipv4pool-ec2-0123456789abcdef0",
    }


def test_eip_is_allocated_from_the_amazon_pool_when_none_is_configured(scaling, ec2):
    scaling.add_public_ip_to_eni("eni-untrust", None)

    assert ec2.args_of("allocate_address") == {"Domain": "vpc"}


def test_configured_pool_reaches_eip_allocation_when_an_interface_is_created(
        scaling, ec2, interfaces_config):
    """The pool set in Terraform on an interface is the pool the EIP comes from."""
    interfaces_config({
        "untrust": {
            "device_index": 2,
            "subnet_id": {"us-east-1a": "subnet-untrust-a"},
            "create_public_ip": True,
            "public_ipv4_pool": "ipv4pool-ec2-0123456789abcdef0",
            "security_group_ids": ["sg-untrust"],
            "source_dest_check": False,
        }
    })
    untrust = VMSeriesInterfaceScaling.create_interface_settings("us-east-1a")[0]

    scaling.create_and_configure_new_network_interface("i-0abc", untrust)

    assert ec2.args_of("allocate_address")["PublicIpv4Pool"] == "ipv4pool-ec2-0123456789abcdef0"


def test_unset_pool_falls_back_to_the_amazon_pool_when_an_interface_is_created(
        scaling, ec2, interfaces_config):
    """`optional(string)` with no value is rendered as an explicit JSON null."""
    interfaces_config({
        "untrust": {
            "device_index": 2,
            "subnet_id": {"us-east-1a": "subnet-untrust-a"},
            "create_public_ip": True,
            "public_ipv4_pool": None,
            "security_group_ids": ["sg-untrust"],
            "source_dest_check": False,
        }
    })
    untrust = VMSeriesInterfaceScaling.create_interface_settings("us-east-1a")[0]

    scaling.create_and_configure_new_network_interface("i-0abc", untrust)

    assert ec2.args_of("allocate_address") == {"Domain": "vpc"}
