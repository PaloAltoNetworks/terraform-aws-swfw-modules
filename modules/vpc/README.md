# Palo Alto Networks VPC Module for AWS

A Terraform module for deploying a VPC in AWS.

One advantage of this module over the [terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)
module is that it does not create multiple resources based on Terraform `count` iterator. This allows for example
[easier removal](https://github.com/PaloAltoNetworks/terraform-best-practices#22-looping) of any single subnet,
without the need to briefly destroy and re-create any other subnet.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name                    = var.name
  cidr_block              = var.vpc_cidr_block
  secondary_cidr_blocks   = var.vpc_secondary_cidr_blocks
  create_internet_gateway = true
  global_tags             = var.global_tags
  vpc_tags                = var.vpc_tags
  security_groups         = var.security_groups
}
```

## Reference
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
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

No modules.

### Resources

| Name | Type |
|------|------|
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_network_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl) | resource |
| [aws_network_acl_association.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_association) | resource |
| [aws_network_acl_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule) | resource |
| [aws_route_table.from_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.from_vgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.from_igw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.from_vgw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_dhcp_options.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options) | resource |
| [aws_vpc_dhcp_options_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association) | resource |
| [aws_vpc_ipv4_cidr_block_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association) | resource |
| [aws_vpn_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/internet_gateway) | data source |
| [aws_route_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_table) | data source |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | Object containing the IPv4 and IPv6 CIDR blocks to assign to a new VPC.<br><br>Properties:<br>- `ipv4`                  - (`string`, optional) the IPv4 CIDR block to assign to the VPC.<br>- `secondary_ipv4`        - (`list(string)`, optional, defaults to `[]`) a list of secondary IPv4 CIDR blocks to assign to VPC.<br>- `assign_generated_ipv6` - (`bool`, optional, defaults to `false`) a boolean flag to assign AWS-provided /56 IPv6 CIDR block.<br><br>Example:<pre>hcl<br>cidr_block = {<br>  ipv4 = "10.0.0.0/16"<br>}</pre> | <pre>object({<br>    ipv4                  = optional(string)<br>    secondary_ipv4        = optional(list(string), [])<br>    assign_generated_ipv6 = optional(bool, false)<br>  })</pre> | n/a | yes |
| <a name="input_create_vpc"></a> [create\_vpc](#input\_create\_vpc) | When set to `true` inputs are used to create a VPC, otherwise - to get data about an existing one. | `bool` | `true` | no |
| <a name="input_internet_gateway"></a> [internet\_gateway](#input\_internet\_gateway) | Object containing the Internet Gateway options.<br><br>Properties:<br>- `create`       - (`bool`, optional, defaults to `true`) a boolean flag to create an Internet Gateway.<br>- `use_existing` - (`bool`, optional, defaults to `false`) a boolean flag to use an existing Internet Gateway.<br>- `name`         - (`string`, optional) the name of the Internet Gateway to create or use.<br>- `route_table`  - (`string`, optional) the name of the route table for the Internet Gateway.<br><br>Example:<pre>hcl<br>internet_gateway = {<br>  create = true<br>}</pre> | <pre>object({<br>    create       = optional(bool, true)<br>    use_existing = optional(bool, false)<br>    name         = optional(string)<br>    route_table  = optional(string)<br>  })</pre> | <pre>{<br>  "create": true<br>}</pre> | no |
| <a name="input_nacls"></a> [nacls](#input\_nacls) | The `nacls` variable is a map of objects, where each object represents an AWS NACL.<br><br>  Properties:<br>  - `name`  - (`string`) the name of the NACL.<br>  - `rules` - (`map(object)`) a map of objects representing the NACL rules. The key of each entry acts as the name of the rule and<br>      needs to be unique across all rules in the NACL. List of attributes available to define a NACL rule:<br>      - `rule_number` - (`number`) the rule number for the NACL rule.<br>      - `type`        - (`string`) specifies if rule will be evaluated on ingress (inbound) or egress (outbound) traffic.<br>      - `protocol`    - (`string`) the protocol. If -1, it means all protocols.<br>      - `action`      - (`string`) the action to take. Valid values are `allow` and `deny`.<br>      - `cidr_block`  - (`string`) the CIDR block to match. If not specified, it means all IP addresses.<br>      - `from_port`   - (`string`, optional) the from port.<br>      - `to_port`     - (`string`, optional) the to port.<br><br>  Example:<pre>nacls = {<br>    trusted_path_monitoring = {<br>      name = "trusted-path-monitoring"<br>      rules = {<br>        allow_other_outbound = {<br>          rule_number = 200<br>          type        = "egress"<br>          protocol    = "-1"<br>          action      = "allow"<br>          cidr_block  = "0.0.0.0/0"<br>        }<br>        allow_inbound = {<br>          rule_number = 300<br>          type        = "ingress"<br>          protocol    = "-1"<br>          action      = "allow"<br>          cidr_block  = "0.0.0.0/0"<br>        }<br>      }<br>    }<br>  }</pre> | <pre>map(object({<br>    name = string<br>    rules = map(object({<br>      rule_number = number<br>      type        = string<br>      protocol    = string<br>      action      = string<br>      cidr_block  = string<br>      from_port   = optional(string)<br>      to_port     = optional(string)<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the VPC to create or use. | `string` | n/a | yes |
| <a name="input_options"></a> [options](#input\_options) | Object containing the VPC options.<br><br>Properties:<br>- `enable_dns_support`      - (`bool`, optional, defaults to `true`) a boolean flag to enable/disable DNS support in the VPC.<br>- `enable_dns_hostnames`    - (`bool`, optional, defaults to `false`) a boolean flag to enable/disable DNS hostnames in the VPC.<br>- `create_dhcp_options`     - (`bool`, optional, defaults to `false`) a boolean flag to create a DHCP options set.<br>- `domain_name`             - (`string`, optional) the DNS name for the DHCP options set.<br>- `domain_name_servers`     - (`list(string)`, optional, defaults to `[]`) a list of DNS server addresses for DHCP options set.<br>- `ntp_servers`             - (`list(string)`, optional, defaults to `[]`) a list of NTP server addresses for DHCP options set.<br>- `instance_tenancy`        - (`string`, optional) the tenancy of instances launched into the VPC.<br>- `map_public_ip_on_launch` - (`bool`, optional, defaults to `false`) a boolean flag to enable/disable public IP on launch.<br>- `propagating_vgws`        - (`list(string)`, optional, defaults to `[]`) a list of VGWs to propagate routes to.<br><br>Example:<pre>hcl<br>options = {<br>  enable_dns_support   = true<br>  enable_dns_hostnames = true<br>  create_dhcp_options  = true<br>}</pre> | <pre>object({<br>    enable_dns_support      = optional(bool, true)<br>    enable_dns_hostnames    = optional(bool, false)<br>    create_dhcp_options     = optional(bool, false)<br>    domain_name             = optional(string)<br>    domain_name_servers     = optional(list(string), [])<br>    ntp_servers             = optional(list(string), [])<br>    instance_tenancy        = optional(string)<br>    map_public_ip_on_launch = optional(bool, false)<br>    propagating_vgws        = optional(list(string), [])<br>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region. | `string` | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | The `security_groups` variable is a map of object, where each object represents an AWS Security Group.<br><br>  Properties:<br>  - `name`        - (`string`) the name of the security group.<br>  - `description` - (`string`, optional) the description of the security group.<br>  - `rules`       - (`map(object)`) a map of objects representing the security group rules. The key of each entry acts<br>      as the name of the rule and needs to be unique across all rules in the security group.<br>      List of attributes available to define a security group rule:<br>      - `description`            - (`string`) the description of the rule.<br>      - `type`                   - (`string`) specifies if rule will be evaluated on ingress or egress traffic.<br>      - `from_port`              - (`string`) the from port.<br>      - `to_port`                - (`string`) the to port.<br>      - `protocol`               - (`string`) the protocol.<br>      - `cidr_blocks`            - (`list(string)`) a list of CIDR blocks to allow traffic from/to.<br>      - `ipv6_cidr_blocks`       - (`list(string)`, optional) a list of IPv6 CIDR blocks to allow traffic from/to.<br>      - `prefix_list_ids`        - (`list(string)`, optional) a list of prefix list IDs to allow traffic from/to.<br>      - `self`                   - (`bool`, optional, defaults to `false`) a boolean flag to allow traffic from/to the SG itself.<br>      - `source_security_groups` - (`list(string)`, optional) a list of security group IDs to allow traffic from/to.<br><br>  Example:<pre>security_groups = {<br>    vmseries_mgmt = {<br>      name = "vmseries_mgmt"<br>      rules = {<br>        all_outbound = {<br>          description = "Permit All traffic outbound"<br>          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br>          cidr_blocks = ["0.0.0.0/0"]<br>        }<br>        https = {<br>          description = "Permit HTTPS"<br>          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"<br>          cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)<br>        }<br>        ssh = {<br>          description = "Permit SSH"<br>          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"<br>          cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)<br>        }<br>        panorama_ssh = {<br>          description = "Permit Panorama SSH (Optional)"<br>          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"<br>          cidr_blocks = ["10.0.0.0/8"]<br>        }<br>      }<br>    }<br>  }</pre> | <pre>map(object({<br>    name        = string<br>    description = optional(string, "Security group managed by Terraform")<br>    rules = map(object({<br>      description            = string<br>      type                   = string<br>      from_port              = string<br>      to_port                = string<br>      protocol               = string<br>      cidr_blocks            = list(string)<br>      ipv6_cidr_blocks       = optional(list(string))<br>      prefix_list_ids        = optional(list(string))<br>      self                   = optional(bool, false)<br>      source_security_groups = optional(list(string))<br>    }))<br>  }))</pre> | `{}` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | The `subnets` variable is a map of objects, where each object represents an AWS Subnet.<br><br>  Properties:<br>  - `az`                      - (`string`) the availability zone for the subnet.<br>  - `cidr_block`              - (`string`) the CIDR block for the subnet.<br>  - `ipv6_cidr_block`         - (`string`, optional) the IPv6 CIDR block for the subnet.<br>  - `subnet_group`            - (`string`) the name of the subnet group.<br>  - `name`                    - (`string`) the name of the subnet.<br>  - `nacl`                    - (`string`, optional) the name of the NACL to associate with the subnet.<br>  - `create_subnet`           - (`bool`, optional, defaults to `true`) a boolean flag to create a subnet.<br>  - `create_route_table`      - (`bool`, optional, defaults to `true`) a boolean flag to create a route table.<br>  - `route_table_name`        - (`string`, optional) the name of the route table.<br>  - `existing_route_table_id` - (`string`, optional) the ID of the existing route table.<br>  - `associate_route_table`   - (`bool`, optional, defaults to `true`) a boolean flag to associate a route table.<br>  - `tags`                    - (`map(string)`, optional) a map of arbitrary tags to apply to the subnet.<br><br>  Example:<pre>hcl<br>  subnets = {<br>    app1_vma    = { az = "a", cidr_block = "10.104.0.0/24", subnet_group = "app1_vm", name = "app1_vm1" }<br>    app1_vmb    = { az = "b", cidr_block = "10.104.128.0/24", subnet_group = "app1_vm", name = "app1_vm2" }<br>    app1_lba    = { az = "a", cidr_block = "10.104.2.0/24", subnet_group = "app1_lb", name = "app1_lb1" }<br>    app1_lbb    = { az = "b", cidr_block = "10.104.130.0/24", subnet_group = "app1_lb", name = "app1_lb2" }<br>    app1_gwlbea = { az = "a", cidr_block = "10.104.3.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe1" }<br>    app1_gwlbeb = { az = "b", cidr_block = "10.104.131.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe2" }<br>  }</pre> | <pre>map(object({<br>    az                      = string<br>    cidr_block              = string<br>    ipv6_cidr_block         = optional(string)<br>    subnet_group            = string<br>    name                    = string<br>    nacl                    = optional(string)<br>    create_subnet           = optional(bool, true)<br>    create_route_table      = optional(bool, true)<br>    route_table_name        = optional(string)<br>    existing_route_table_id = optional(string)<br>    associate_route_table   = optional(bool, true)<br>    tags                    = optional(map(string))<br>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Optional map of arbitrary tags to apply to all the created resources. | `map(string)` | `{}` | no |
| <a name="input_vpc_tags"></a> [vpc\_tags](#input\_vpc\_tags) | Optional map of arbitrary tags to apply to VPC resource. | `map(string)` | `{}` | no |
| <a name="input_vpn_gateway"></a> [vpn\_gateway](#input\_vpn\_gateway) | Object containing the VPN Gateway options.<br><br>Properties:<br>- `create`          - (`bool`, optional, defaults to `false`) a boolean flag to create a VPN Gateway.<br>- `amazon_side_asn` - (`string`, optional) the ASN for the Amazon side of the gateway.<br>- `name`            - (`string`, optional) the name of the VPN Gateway to create.<br>- `route_table`     - (`string`, optional) the name of the route table for VPN Gateway.<br><br>Example:<pre>hcl<br>vpn_gateway = {<br>  create = false<br>}</pre> | <pre>object({<br>    create          = optional(bool, false)<br>    amazon_side_asn = optional(string)<br>    name            = optional(string)<br>    route_table     = optional(string)<br>  })</pre> | <pre>{<br>  "create": false<br>}</pre> | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_has_secondary_cidrs"></a> [has\_secondary\_cidrs](#output\_has\_secondary\_cidrs) | n/a |
| <a name="output_id"></a> [id](#output\_id) | The VPC identifier (either created or pre-existing). |
| <a name="output_igw_as_next_hop_set"></a> [igw\_as\_next\_hop\_set](#output\_igw\_as\_next\_hop\_set) | The object is suitable for use as `vpc_route` module's input `next_hop_set`. |
| <a name="output_internet_gateway"></a> [internet\_gateway](#output\_internet\_gateway) | The entire Internet Gateway object |
| <a name="output_internet_gateway_route_table"></a> [internet\_gateway\_route\_table](#output\_internet\_gateway\_route\_table) | The Route Table object created to handle traffic from Internet Gateway (IGW). |
| <a name="output_nacl_ids"></a> [nacl\_ids](#output\_nacl\_ids) | Map of NACL -> ID (newly created). |
| <a name="output_name"></a> [name](#output\_name) | The VPC Name Tag (either created or pre-existing). |
| <a name="output_route_tables"></a> [route\_tables](#output\_route\_tables) | n/a |
| <a name="output_security_group_ids"></a> [security\_group\_ids](#output\_security\_group\_ids) | Map of Security Group Name -> ID (newly created). |
| <a name="output_subnets"></a> [subnets](#output\_subnets) | n/a |
| <a name="output_vpc"></a> [vpc](#output\_vpc) | The entire VPC object (either created or pre-existing). |
| <a name="output_vpn_gateway"></a> [vpn\_gateway](#output\_vpn\_gateway) | The entire Virtual Private Gateway object. It is null when `create_vpn_gateway` is false. |
| <a name="output_vpn_gateway_as_next_hop_set"></a> [vpn\_gateway\_as\_next\_hop\_set](#output\_vpn\_gateway\_as\_next\_hop\_set) | The object is suitable for use as `vpc_route` module's input `next_hop_set`. |
| <a name="output_vpn_gateway_route_table"></a> [vpn\_gateway\_route\_table](#output\_vpn\_gateway\_route\_table) | The Route Table object created to handle traffic from Virtual Private Gateway (VGW). It is null when `create_vpn_gateway` is false. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
