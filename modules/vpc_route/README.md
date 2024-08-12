# Palo Alto Networks VPC Route Module for AWS

A Terraform module for deploying a VPC route in AWS cloud.

## Usage

```hcl
module "vpc" {
  source = "../../modules/vpc"

  name                    = var.name
  cidr_block              = var.vpc_cidr_block
  secondary_cidr_blocks   = var.vpc_secondary_cidr_blocks
  global_tags             = var.global_tags
  vpc_tags                = var.vpc_tags
  security_groups         = var.security_groups
}

module "subnet_sets" {
  source   = "../../modules/subnet_set"

  for_each = toset(distinct([for _, v in var.subnets : v.set]))
  
  name   = each.key
  cidrs  = { for k, v in var.subnets : k => v if v.set == each.key }
  vpc_id = module.vpc.id
}

module "nat_gateway_set" {
  source = "../../modules/nat_gateway_set"

  subnets = module.subnet_sets["natgw-1"].subnets
}

module "vpc_route" {
  source = "../../modules/vpc_route"

  for_each = {
    mgmt = {
      route_table_ids = module.subnet_sets["mgmt-1"].unique_route_table_ids
      next_hop_set    = module.vpc.igw_as_next_hop_set
      to_cidr         = var.igw_routing_destination_cidr
    }
    public = {
      route_table_ids = module.subnet_sets["public-1"].unique_route_table_ids
      next_hop_set    = module.nat_gateway_set.next_hop_set
      to_cidr         = var.igw_routing_destination_cidr
    }
    natgw = {
      route_table_ids = module.subnet_sets["natgw-1"].unique_route_table_ids
      next_hop_set    = module.vpc.igw_as_next_hop_set
      to_cidr         = var.igw_routing_destination_cidr
    }
  }

  route_table_ids = each.value.route_table_ids
  next_hop_set    = each.value.next_hop_set
  to_cidr         = each.value.to_cidr
}
```

## Reference
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0, < 2.0.0 |
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
| [aws_route.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_az"></a> [az](#input\_az) | The Availability Zone of the route table | `string` | n/a | yes |
| <a name="input_carrier_gateway_id"></a> [carrier\_gateway\_id](#input\_carrier\_gateway\_id) | ID of the carrier gateway | `string` | `null` | no |
| <a name="input_core_network_arn"></a> [core\_network\_arn](#input\_core\_network\_arn) | The ARN of the core network | `string` | `null` | no |
| <a name="input_destination_type"></a> [destination\_type](#input\_destination\_type) | Type of destination: "ipv4", "ipv6" or "mpl". | `string` | `"ipv4"` | no |
| <a name="input_egress_only_gateway_id"></a> [egress\_only\_gateway\_id](#input\_egress\_only\_gateway\_id) | ID of the Egress Only Internet Gateway | `string` | `null` | no |
| <a name="input_internet_gateway_id"></a> [internet\_gateway\_id](#input\_internet\_gateway\_id) | ID of the Internet Gateway | `string` | `null` | no |
| <a name="input_local_gateway_id"></a> [local\_gateway\_id](#input\_local\_gateway\_id) | ID of the Local Gateway | `string` | `null` | no |
| <a name="input_managed_prefix_list_id"></a> [managed\_prefix\_list\_id](#input\_managed\_prefix\_list\_id) | ID of managed prefix list, which is going to be set as destination in route | `string` | `null` | no |
| <a name="input_nat_gateways"></a> [nat\_gateways](#input\_nat\_gateways) | Map of NAT Gateways to use as next hop. | <pre>map(object({<br>    id           = string<br>    subnet_group = string<br>    az           = string<br>  }))</pre> | `{}` | no |
| <a name="input_network_interfaces"></a> [network\_interfaces](#input\_network\_interfaces) | Map of network interfaces to use as next hop. | <pre>map(object({<br>    id           = string<br>    subnet_group = string<br>    az           = string<br>  }))</pre> | `{}` | no |
| <a name="input_next_hop_type"></a> [next\_hop\_type](#input\_next\_hop\_type) | Type of next hop. | `string` | n/a | yes |
| <a name="input_route_tables"></a> [route\_tables](#input\_route\_tables) | Map of route tables to create routes in. | <pre>map(object({<br>    id           = string<br>    subnet_group = string<br>    az           = string<br>  }))</pre> | n/a | yes |
| <a name="input_to_cidr"></a> [to\_cidr](#input\_to\_cidr) | The CIDR to match the packet's destination field. If they match, the route can be used for the packet. For example "0.0.0.0/0". | `string` | n/a | yes |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | ID of the transit gateway | `string` | `null` | no |
| <a name="input_vpc_endpoints"></a> [vpc\_endpoints](#input\_vpc\_endpoints) | Map of VPC Endpoints to use as next hop. | <pre>map(object({<br>    id           = string<br>    subnet_group = string<br>    az           = string<br>  }))</pre> | `{}` | no |
| <a name="input_vpc_peering_connection_id"></a> [vpc\_peering\_connection\_id](#input\_vpc\_peering\_connection\_id) | ID of the VPC Peering Connection | `string` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_route_details"></a> [route\_details](#output\_route\_details) | n/a |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
