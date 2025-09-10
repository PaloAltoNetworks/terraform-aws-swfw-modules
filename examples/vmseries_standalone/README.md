---
show_in_hub: false
---
# Palo Alto Networks VM-Series example

A Terraform example for deploying a one or more instances of VM-Series in one or more VPCs in AWS Cloud.

This example can be used to familarize oneself with both the VM-Series NGFW  and Terraform - it creates a single instance of virtualized firewall in a Security VPC with a management-only interface and lacks any traffic inspection.

For a more complex scenario of using the `vmseries` module - including traffic inspection, check the rest of our [Examples](https://github.com/PaloAltoNetworks/terraform-aws-swfw-modules/tree/main/examples).

**NOTE 1:**
VM-Series will take a serveral minutes to bootup during the initial setup.

**NOTE 2:**
The Security Group attached to the Management interface uses an inbound rule allowing traffic to port `22` and `443` from `0.0.0.0/0`, which means that SSH and HTTP access to the NFGW is possible from all over the Internet. You should update the Security Group rules and limit access to the Management interface, for example - to only the public IP address from which you will connect to VM-Series.

## Topology

The topology consists of :
 - VPC with 1 subnet in 1 availability zones
 - 1 VM-Series instances with a public IP address and static private IP address

<img src="https://github.com/PaloAltoNetworks/terraform-aws-swfw-modules/assets/2110772/602ad0ee-26d0-4b69-9d4c-552031bdc7ca" width="45%" height="45%" >

## PAN-OS software version

Example was prepared for PAN-OS in **10.2.3** version. For more information about recommended software versions see [Support PAN-OS Software Release Guidance](https://pandocs.tech/fw/184p-link3).

## Bootstrap

Terraform example is deploying VM-Series with a basic configuration in [bootstrap package](https://docs.paloaltonetworks.com/vm-series/10-2/vm-series-deployment/bootstrap-the-vm-series-firewall/bootstrap-package) located in S3 bucket. [User Data](https://docs.paloaltonetworks.com/vm-series/10-2/vm-series-deployment/bootstrap-the-vm-series-firewall/choose-a-bootstrap-method) is configured to point to the S3 bucket with bootstrap package. Bootstrap package contains folders like "config", "license", "software" and "content" to initialize the firewall with a basic configuration or license it during bootstrap. In the example, [init-cfg.txt](https://docs.paloaltonetworks.com/vm-series/10-2/vm-series-deployment/bootstrap-the-vm-series-firewall/create-the-init-cfgtxt-file/init-cfgtxt-file-components) file is dynamically created in S3 bucket using the provided bootstrap options. It's also possible to upload files to bootstrap package by placing them under the relevant folders in the `source_root_directory` of `bootstrap` module (e.g. you may place a `authcodes` file under "license" folder to license the firewall during bootstrap). See [bootstrapping VM-Series firewall on AWS](https://docs.paloaltonetworks.com/vm-series/10-2/vm-series-deployment/bootstrap-the-vm-series-firewall/bootstrap-the-vm-series-firewall-in-aws) for more options on bootstrapping VM-Series on AWS.

## Prerequisites

1. Configure the Terraform [AWS provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## Usage

1. Access AWS CloudShell or any other environment which has access to your AWS account
2. Clone the repository: `git clone https://github.com/PaloAltoNetworks/terraform-aws-swfw-modules`
3. Go to Panorama example: `cd terraform-aws-swfw-modules/examples/vmseries_standalone`
4. Copy `example.tfvars` or `example_ipv6.tfvars` into `terraform.tfvars`
5. Review `terraform.tfvars` file, especially with lines commented by ` # TODO: update here`
6. Initialize Terraform: `terraform init`
7. Prepare plan: `terraform plan`
8. Deploy infrastructure: `terraform apply -auto-approve`
9. Destroy infrastructure if needed: `terraform destroy -auto-approve`

## Configuration

1. Get public IP for each VM-Series instance(s): `terraform output vmseries_public_ips`
2. Connect to the Panorama instance(s) via SSH using your associated private key: `ssh admin@x.x.x.x -i /PATH/TO/YOUR/KEY/id_rsa`
3. Set `admin` password:

```
> configure
# set mgt-config users admin password
```

4. Optional (only for IPv6 example) | By default IPv6 on management interface is disabled. To enable it type in CLI:

```
> configure
# set deviceconfig system ipv6-type dynamic non-temporary-address yes
# set deviceconfig system ipv6-gw-type dynamic
```

## Access VM-Series

Use a web browser to access https://x.x.x.x and login with admin and your previously configured password

## Reference
<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.17 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.17 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bootstrap"></a> [bootstrap](#module\_bootstrap) | ../../modules/bootstrap | n/a |
| <a name="module_natgw_set"></a> [natgw\_set](#module\_natgw\_set) | ../../modules/nat_gateway_set | n/a |
| <a name="module_subnet_sets"></a> [subnet\_sets](#module\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_vmseries"></a> [vmseries](#module\_vmseries) | ../../modules/vmseries | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |
| <a name="module_vpc_routes"></a> [vpc\_routes](#module\_vpc\_routes) | ../../modules/vpc_route | n/a |

### Resources

| Name | Type |
|------|------|
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags configured for all provisioned resources | `any` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.) | `string` | n/a | yes |
| <a name="input_natgws"></a> [natgws](#input\_natgws) | A map defining NAT Gateways.<br/><br/>Following properties are available:<br/>- `nat_gateway_names`: A map, where each key is an Availability Zone name, for example "eu-west-1b". <br/>  Each value in the map is a custom name of a NAT Gateway in that Availability Zone.<br/>- `vpc`: key of the VPC<br/>- `subnet_group`: key of the subnet\_group<br/>- `nat_gateway_tags`: A map containing NAT GW tags<br/>- `create_eip`: Defaults to true, uses a data source to find EIP when set to false<br/>- `eips`: Optional map of Elastic IP attributes. Each key must be an Availability Zone name. <br/><br/>Example:<pre>natgws = {<br/>  sec_natgw = {<br/>    vpc = "security_vpc"<br/>    subnet_group = "natgw"<br/>    nat_gateway_names = {<br/>      "eu-west-1a" = "nat-gw-1"<br/>      "eu-west-1b" = "nat-gw-2"<br/>    }<br/>    eips ={<br/>      "eu-west-1a" = { <br/>        name = "natgw-1-pip"<br/>      }<br/>    }<br/>  }<br/>}</pre> | <pre>map(object({<br/>    create_nat_gateway = optional(bool, true)<br/>    nat_gateway_names  = optional(map(string), {})<br/>    vpc                = string<br/>    subnet_group       = string<br/>    nat_gateway_tags   = optional(map(string), {})<br/>    create_eip         = optional(bool, true)<br/>    eips = optional(map(object({<br/>      name      = optional(string)<br/>      public_ip = optional(string)<br/>      id        = optional(string)<br/>      eip_tags  = optional(map(string), {})<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes | `string` | `""` | no |
| <a name="input_vmseries"></a> [vmseries](#input\_vmseries) | A map defining VM-Series instances<br/><br/>Following properties are available:<br/>- `instances`: map of VM-Series instances<br/>- `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama<br/>- `panos_version`: PAN-OS version used for VM-Series<br/>- `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series<br/>- `vpc`: key of VPC<br/>- `gwlb`: key of GWLB<br/>- `subinterfaces`: configuration of network subinterfaces used to map with GWLB endpoints<br/>- `system_services`: map of system services<br/>- `application_lb`: ALB placed in front of the Firewalls' public interfaces<br/>- `network_lb`: NLB placed in front of the Firewalls' public interfaces<br/><br/>Example:<pre>vmseries = {<br/>  vmseries = {<br/>    instances = {<br/>      "01" = { az = "eu-central-1a" }<br/>      "02" = { az = "eu-central-1b" }<br/>    }<br/><br/>    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`<br/>    bootstrap_options = {<br/>      mgmt-interface-swap         = "enable"<br/>      plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"<br/>      dhcp-send-hostname          = "yes"<br/>      dhcp-send-client-id         = "yes"<br/>      dhcp-accept-server-hostname = "yes"<br/>      dhcp-accept-server-domain   = "yes"<br/>    }<br/><br/>    panos_version = "10.2.3"        # TODO: update here<br/>    ebs_kms_id    = "alias/aws/ebs" # TODO: update here<br/><br/>    # Value of `vpc` must match key of objects stored in `vpcs`<br/>    vpc = "security_vpc"<br/><br/>    # Value of `gwlb` must match key of objects stored in `gwlbs`<br/>    gwlb = "security_gwlb"<br/><br/>    interfaces = {<br/>      private = {<br/>        device_index      = 0<br/>        security_group    = "vmseries_private"<br/>        vpc               = "security_vpc"<br/>        subnet_group            = "private"<br/>        create_public_ip  = false<br/>        source_dest_check = false<br/>      }<br/>      mgmt = {<br/>        device_index      = 1<br/>        security_group    = "vmseries_mgmt"<br/>        vpc               = "security_vpc"<br/>        subnet_group            = "mgmt"<br/>        create_public_ip  = true<br/>        source_dest_check = true<br/>      }<br/>      public = {<br/>        device_index      = 2<br/>        security_group    = "vmseries_public"<br/>        vpc               = "security_vpc"<br/>        subnet_group            = "public"<br/>        create_public_ip  = true<br/>        source_dest_check = false<br/>      }<br/>    }<br/><br/>    # Value of `gwlb_endpoint` must match key of objects stored in `gwlb_endpoints`<br/>    subinterfaces = {<br/>      inbound = {<br/>        app1 = {<br/>          gwlb_endpoint = "app1_inbound"<br/>          subinterface  = "ethernet1/1.11"<br/>        }<br/>        app2 = {<br/>          gwlb_endpoint = "app2_inbound"<br/>          subinterface  = "ethernet1/1.12"<br/>        }<br/>      }<br/>      outbound = {<br/>        only_1_outbound = {<br/>          gwlb_endpoint = "security_gwlb_outbound"<br/>          subinterface  = "ethernet1/1.20"<br/>        }<br/>      }<br/>      eastwest = {<br/>        only_1_eastwest = {<br/>          gwlb_endpoint = "security_gwlb_eastwest"<br/>          subinterface  = "ethernet1/1.30"<br/>        }<br/>      }<br/>    }<br/><br/>    system_services = {<br/>      dns_primary = "4.2.2.2"      # TODO: update here<br/>      dns_secondy = null           # TODO: update here<br/>      ntp_primary = "pool.ntp.org" # TODO: update here<br/>      ntp_secondy = null           # TODO: update here<br/>    }<br/>  }<br/>}</pre> | <pre>map(object({<br/>    instances = map(object({<br/>      az   = string<br/>      name = optional(string)<br/>    }))<br/><br/>    bootstrap_options = object({<br/>      hostname                              = optional(string)<br/>      mgmt-interface-swap                   = string<br/>      plugin-op-commands                    = string<br/>      op-command-modes                      = optional(string)<br/>      panorama-server                       = string<br/>      panorama-server-2                     = optional(string)<br/>      auth-key                              = optional(string)<br/>      vm-auth-key                           = optional(string)<br/>      dgname                                = string<br/>      tplname                               = optional(string)<br/>      cgname                                = optional(string)<br/>      dns-primary                           = optional(string)<br/>      dns-secondary                         = optional(string)<br/>      dhcp-send-hostname                    = optional(string)<br/>      dhcp-send-client-id                   = optional(string)<br/>      dhcp-accept-server-hostname           = optional(string)<br/>      dhcp-accept-server-domain             = optional(string)<br/>      authcodes                             = optional(string)<br/>      vm-series-auto-registration-pin-id    = optional(string)<br/>      vm-series-auto-registration-pin-value = optional(string)<br/>    })<br/><br/>    panos_version                          = string<br/>    vmseries_ami_id                        = optional(string)<br/>    vmseries_product_code                  = optional(string, "6njl1pau431dv1qxipg63mvah")<br/>    include_deprecated_ami                 = optional(bool, false)<br/>    instance_type                          = optional(string, "m5.xlarge")<br/>    ebs_encrypted                          = optional(bool, true)<br/>    ebs_kms_id                             = optional(string, "alias/aws/ebs")<br/>    enable_instance_termination_protection = optional(bool, false)<br/>    enable_monitoring                      = optional(bool, false)<br/>    fw_license_type                        = optional(string, "byol")<br/><br/>    vpc  = string<br/>    gwlb = optional(string)<br/><br/>    interfaces = map(object({<br/>      device_index       = number<br/>      name               = optional(string)<br/>      description        = optional(string)<br/>      security_group     = string<br/>      subnet_group       = string<br/>      create_public_ip   = optional(bool, false)<br/>      eip_allocation_id  = optional(string)<br/>      source_dest_check  = optional(bool, false)<br/>      private_ips        = optional(list(string))<br/>      ipv6_address_count = optional(number, null)<br/>      public_ipv4_pool   = optional(string)<br/>    }))<br/><br/>    subinterfaces = optional(map(map(object({<br/>      gwlb_endpoint = string<br/>      subinterface  = string<br/>    }))), {})<br/><br/>    tags = optional(map(string))<br/><br/>    system_services = object({<br/>      dns_primary = string<br/>      dns_secondy = optional(string)<br/>      ntp_primary = string<br/>      ntp_secondy = optional(string)<br/>    })<br/><br/>    application_lb = optional(object({<br/>      name           = optional(string)<br/>      subnet_group   = optional(string)<br/>      security_group = optional(string)<br/>      rules          = optional(any)<br/>    }), {})<br/><br/>    network_lb = optional(object({<br/>      name         = optional(string)<br/>      subnet_group = optional(string)<br/>      rules        = optional(any)<br/>    }), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | A map defining VPCs with security groups and subnets.<br/><br/>Following properties are available:<br/>- `name`: VPC name<br/>- `cidr`: CIDR for VPC<br/>- `security_groups`: map of security groups<br/>- `subnets`: map of subnets with properties:<br/>    - `az`: availability zone<br/>    - `subnet_group`: identity of the same purpose subnets group such as management<br/>- `routes`: map of routes with properties:<br/>    - `vpc`: key of the VPC<br/>    - `subnet_group`: key of the subnet group<br/>    - `next_hop_key`: must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources<br/>    - `next_hop_type`: internet\_gateway, nat\_gateway, transit\_gateway\_attachment or gwlbe\_endpoint<br/><br/>Example:<pre>vpcs = {<br/>  example_vpc = {<br/>    name = "example-spoke-vpc"<br/>    cidr = "10.104.0.0/16"<br/>    nacls = {<br/>      trusted_path_monitoring = {<br/>        name               = "trusted-path-monitoring"<br/>        rules = {<br/>          allow_inbound = {<br/>            rule_number = 300<br/>            egress      = false<br/>            protocol    = "-1"<br/>            rule_action = "allow"<br/>            cidr_block  = "0.0.0.0/0"<br/>            from_port   = null<br/>            to_port     = null<br/>          }<br/>        }<br/>      }<br/>    }<br/>    security_groups = {<br/>      example_vm = {<br/>        name = "example_vm"<br/>        rules = {<br/>          all_outbound = {<br/>            description = "Permit All traffic outbound"<br/>            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br/>            cidr_blocks = ["0.0.0.0/0"]<br/>          }<br/>        }<br/>      }<br/>    }<br/>    subnets = {<br/>      "10.104.0.0/24"   = { az = "eu-central-1a", subnet_group = "vm", nacl = null }<br/>      "10.104.128.0/24" = { az = "eu-central-1b", subnet_group = "vm", nacl = null }<br/>    }<br/>    routes = {<br/>      vm_default = {<br/>        vpc           = "app1_vpc"<br/>        subnet_group        = "app1_vm"<br/>        to_cidr       = "0.0.0.0/0"<br/>        next_hop_key  = "app1"<br/>        next_hop_type = "transit_gateway_attachment"<br/>      }<br/>    }<br/>  }<br/>}</pre> | <pre>map(object({<br/>    name                             = string<br/>    create_vpc                       = optional(bool, true)<br/>    cidr                             = string<br/>    secondary_cidr_blocks            = optional(list(string), [])<br/>    assign_generated_ipv6_cidr_block = optional(bool)<br/>    use_internet_gateway             = optional(bool, false)<br/>    name_internet_gateway            = optional(string)<br/>    create_internet_gateway          = optional(bool, true)<br/>    route_table_internet_gateway     = optional(string)<br/>    create_vpn_gateway               = optional(bool, false)<br/>    vpn_gateway_amazon_side_asn      = optional(string)<br/>    name_vpn_gateway                 = optional(string)<br/>    route_table_vpn_gateway          = optional(string)<br/>    enable_dns_hostnames             = optional(bool, true)<br/>    enable_dns_support               = optional(bool, true)<br/>    instance_tenancy                 = optional(string, "default")<br/>    nacls = optional(map(object({<br/>      name = string<br/>      rules = map(object({<br/>        rule_number = number<br/>        egress      = bool<br/>        protocol    = string<br/>        rule_action = string<br/>        cidr_block  = string<br/>        from_port   = optional(number)<br/>        to_port     = optional(number)<br/>      }))<br/>    })), {})<br/>    security_groups = optional(map(object({<br/>      name = string<br/>      rules = map(object({<br/>        description            = optional(string)<br/>        type                   = string<br/>        cidr_blocks            = optional(list(string))<br/>        ipv6_cidr_blocks       = optional(list(string))<br/>        from_port              = string<br/>        to_port                = string<br/>        protocol               = string<br/>        prefix_list_ids        = optional(list(string))<br/>        source_security_groups = optional(list(string))<br/>        self                   = optional(bool)<br/>      }))<br/>    })), {})<br/>    subnets = optional(map(object({<br/>      name                    = optional(string, "")<br/>      az                      = string<br/>      subnet_group            = string<br/>      nacl                    = optional(string)<br/>      create_subnet           = optional(bool, true)<br/>      create_route_table      = optional(bool, true)<br/>      existing_route_table_id = optional(string)<br/>      route_table_name        = optional(string)<br/>      associate_route_table   = optional(bool, true)<br/>      local_tags              = optional(map(string), {})<br/>      map_public_ip_on_launch = optional(bool, false)<br/>    })), {})<br/>    routes = optional(map(object({<br/>      vpc                    = string<br/>      subnet_group           = string<br/>      to_cidr                = string<br/>      next_hop_key           = string<br/>      next_hop_type          = string<br/>      destination_type       = optional(string, "ipv4")<br/>      managed_prefix_list_id = optional(string)<br/>    })), {})<br/>    create_dhcp_options = optional(bool, false)<br/>    domain_name         = optional(string)<br/>    domain_name_servers = optional(list(string))<br/>    ntp_servers         = optional(list(string))<br/>    vpc_tags            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_vmseries_ipv6_addresses"></a> [vmseries\_ipv6\_addresses](#output\_vmseries\_ipv6\_addresses) | Map of IPv6 addresses assigned to interfaces in `vmseries` module instances. |
| <a name="output_vmseries_public_ips"></a> [vmseries\_public\_ips](#output\_vmseries\_public\_ips) | Map of public IPs created within `vmseries` module instances. |
<!-- END_TF_DOCS -->
