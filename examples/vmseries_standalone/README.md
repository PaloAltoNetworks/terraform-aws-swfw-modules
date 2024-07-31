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
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.17 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.17 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bootstrap"></a> [bootstrap](#module\_bootstrap) | ../../modules/bootstrap | n/a |
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
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags configured for all provisioned resources | `any` | n/a | yes |
| <a name="input_vmseries"></a> [vmseries](#input\_vmseries) | A map defining VM-Series instances<br>Following properties are available:<br>- `instances`: map of VM-Series instances<br>- `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama<br>- `panos_version`: PAN-OS version used for VM-Series<br>- `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series<br>- `vpc`: key of VPC<br>Example:<pre>vmseries = {<br>  vmseries = {<br>    instances = {<br>      "01" = { az = "eu-central-1a" }<br>    }<br>    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`<br>    bootstrap_options = {<br>      mgmt-interface-swap         = "enable"<br>      plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"<br>      dhcp-send-hostname          = "yes"<br>      dhcp-send-client-id         = "yes"<br>      dhcp-accept-server-hostname = "yes"<br>      dhcp-accept-server-domain   = "yes"<br>    }<br>    panos_version = "10.2.3"        # TODO: update here<br>    ebs_kms_id    = "alias/aws/ebs" # TODO: update here<br><br>    # Value of `vpc` must match key of objects stored in `vpcs`<br>    vpc = "security_vpc"<br><br>    interfaces = {<br>      mgmt = {<br>        device_index      = 1<br>        private_ip        = "10.100.0.4"<br>        security_group    = "vmseries_mgmt"<br>        vpc               = "security_vpc"<br>        subnet_group      = "mgmt"<br>        create_public_ip  = true<br>        source_dest_check = true<br>        eip_allocation_id = null<br>      }<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    instances = map(object({<br>      az = string<br>    }))<br><br>    bootstrap_options = object({<br>      mgmt-interface-swap         = string<br>      panorama-server             = string<br>      tplname                     = string<br>      dgname                      = string<br>      plugin-op-commands          = string<br>      dhcp-send-hostname          = string<br>      dhcp-send-client-id         = string<br>      dhcp-accept-server-hostname = string<br>      dhcp-accept-server-domain   = string<br>    })<br><br>    panos_version = string<br>    ebs_kms_id    = string<br><br>    vpc = string<br><br>    interfaces = map(object({<br>      device_index       = number<br>      security_group     = string<br>      vpc                = string<br>      subnet_group       = string<br>      create_public_ip   = bool<br>      private_ip         = map(string)<br>      ipv6_address_count = number<br>      source_dest_check  = bool<br>      eip_allocation_id  = map(string)<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | A map defining VPCs with security groups and subnets.<br><br>Following properties are available:<br>- `name`: VPC name<br>- `cidr_block`: Object containing the IPv4 and IPv6 CIDR blocks to assign to a new VPC<br>- `subnets`: map of subnets with properties<br>- `routes`: map of routes with properties<br>- `nacls`: map of network ACLs<br>- `security_groups`: map of security groups<br><br>Example:<pre>vpcs = {<br>  app1_vpc = {<br>    name = "app1-spoke-vpc"<br>    cidr_block = {<br>      ipv4 = "10.104.0.0/16"<br>    }<br>    subnets = {<br>      app1_vma    = { az = "a", cidr_block = "10.104.0.0/24", subnet_group = "app1_vm", name = "app1_vm1" }<br>      app1_vmb    = { az = "b", cidr_block = "10.104.128.0/24", subnet_group = "app1_vm", name = "app1_vm2" }<br>      app1_lba    = { az = "a", cidr_block = "10.104.2.0/24", subnet_group = "app1_lb", name = "app1_lb1" }<br>      app1_lbb    = { az = "b", cidr_block = "10.104.130.0/24", subnet_group = "app1_lb", name = "app1_lb2" }<br>      app1_gwlbea = { az = "a", cidr_block = "10.104.3.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe1" }<br>      app1_gwlbeb = { az = "b", cidr_block = "10.104.131.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe2" }<br>    }<br>    routes = {<br>      vm_default = {<br>        vpc           = "app1_vpc"<br>        subnet_group  = "app1_vm"<br>        to_cidr       = "0.0.0.0/0"<br>        next_hop_key  = "app1"<br>        next_hop_type = "transit_gateway_attachment"<br>      }<br>      gwlbe_default = {<br>        vpc           = "app1_vpc"<br>        subnet_group  = "app1_gwlbe"<br>        to_cidr       = "0.0.0.0/0"<br>        next_hop_key  = "app1_vpc"<br>        next_hop_type = "internet_gateway"<br>      }<br>      lb_default = {<br>        vpc           = "app1_vpc"<br>        subnet_group  = "app1_lb"<br>        to_cidr       = "0.0.0.0/0"<br>        next_hop_key  = "app1_inbound"<br>        next_hop_type = "gwlbe_endpoint"<br>      }<br>    }<br>    nacls = {}<br>    security_groups = {<br>      app1_vm = {<br>        name = "app1_vm"<br>        rules = {<br>          all_outbound = {<br>            description = "Permit All traffic outbound"<br>            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>            cidr_blocks = ["0.0.0.0/0"]<br>          }<br>          ssh = {<br>            description = "Permit SSH"<br>            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"<br>            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"]<br>          }<br>          https = {<br>            description = "Permit HTTPS"<br>            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"<br>            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"]<br>          }<br>          http = {<br>            description = "Permit HTTP"<br>            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"<br>            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"]<br>          }<br>        }<br>      }<br>    }<br>  }<br>}</pre> | <pre>map(object({<br>    name = string<br>    cidr_block = object({<br>      ipv4                  = optional(string)<br>      secondary_ipv4        = optional(list(string), [])<br>      assign_generated_ipv6 = optional(bool, false)<br>    })<br>    nacls = map(object({<br>      name = string<br>      rules = map(object({<br>        rule_number = number<br>        type        = string<br>        protocol    = string<br>        action      = string<br>        cidr_block  = string<br>        from_port   = optional(string)<br>        to_port     = optional(string)<br>      }))<br>    }))<br>    security_groups = map(object({<br>      name        = string<br>      description = optional(string, "Security group managed by Terraform")<br>      rules = map(object({<br>        description      = string<br>        type             = string<br>        from_port        = string<br>        to_port          = string<br>        protocol         = string<br>        cidr_blocks      = optional(list(string))<br>        ipv6_cidr_blocks = optional(list(string))<br>      }))<br>    }))<br>    subnets = map(object({<br>      subnet_group            = string<br>      az                      = string<br>      name                    = string<br>      cidr_block              = string<br>      ipv6_cidr_block         = optional(string)<br>      ipv6_index              = optional(number)<br>      nacl                    = optional(string)<br>      create_subnet           = optional(bool, true)<br>      create_route_table      = optional(bool, true)<br>      existing_route_table_id = optional(string)<br>      associate_route_table   = optional(bool, true)<br>      route_table_name        = optional(string)<br>      local_tags              = optional(map(string), {})<br>      tags                    = optional(map(string), {})<br>    }))<br>    routes = map(object({<br>      vpc              = string<br>      subnet_group     = string<br>      to_cidr          = string<br>      destination_type = string<br>      next_hop_key     = string<br>      next_hop_type    = string<br>    }))<br>  }))</pre> | `{}` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_vmseries_ipv6_addresses"></a> [vmseries\_ipv6\_addresses](#output\_vmseries\_ipv6\_addresses) | Map of IPv6 addresses assigned to interfaces in `vmseries` module instances. |
| <a name="output_vmseries_public_ips"></a> [vmseries\_public\_ips](#output\_vmseries\_public\_ips) | Map of public IPs created within `vmseries` module instances. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
