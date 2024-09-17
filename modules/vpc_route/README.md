# Palo Alto Networks VPC Route Module for AWS

A Terraform module for deploying a VPC route in AWS cloud.

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
| <a name="input_carrier_gateway_id"></a> [carrier\_gateway\_id](#input\_carrier\_gateway\_id) | ID of the carrier gateway | `string` | `null` | no |
| <a name="input_core_network_arn"></a> [core\_network\_arn](#input\_core\_network\_arn) | The ARN of the core network | `string` | `null` | no |
| <a name="input_destination_type"></a> [destination\_type](#input\_destination\_type) | Type of destination: "ipv4", "ipv6" or "mpl". | `string` | `"ipv4"` | no |
| <a name="input_egress_only_gateway_id"></a> [egress\_only\_gateway\_id](#input\_egress\_only\_gateway\_id) | ID of the Egress Only Internet Gateway | `string` | `null` | no |
| <a name="input_internet_gateway_id"></a> [internet\_gateway\_id](#input\_internet\_gateway\_id) | ID of the Internet Gateway | `string` | `null` | no |
| <a name="input_local_gateway_id"></a> [local\_gateway\_id](#input\_local\_gateway\_id) | ID of the Local Gateway | `string` | `null` | no |
| <a name="input_managed_prefix_list_id"></a> [managed\_prefix\_list\_id](#input\_managed\_prefix\_list\_id) | ID of managed prefix list, which is going to be set as destination in route | `string` | `null` | no |
| <a name="input_nat_gateway_id"></a> [nat\_gateway\_id](#input\_nat\_gateway\_id) | ID of the NAT Gateway | `string` | `null` | no |
| <a name="input_network_interface_id"></a> [network\_interface\_id](#input\_network\_interface\_id) | ID of the network interface | `string` | `null` | no |
| <a name="input_next_hop_type"></a> [next\_hop\_type](#input\_next\_hop\_type) | Type of next hop. | `string` | n/a | yes |
| <a name="input_route_table_id"></a> [route\_table\_id](#input\_route\_table\_id) | ID of the route table | `string` | n/a | yes |
| <a name="input_to_cidr"></a> [to\_cidr](#input\_to\_cidr) | The CIDR to match the packet's destination field. If they match, the route can be used for the packet. For example "0.0.0.0/0". | `string` | n/a | yes |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | ID of the transit gateway | `string` | `null` | no |
| <a name="input_vpc_endpoint_id"></a> [vpc\_endpoint\_id](#input\_vpc\_endpoint\_id) | ID of the VPC Endpoint | `string` | `null` | no |
| <a name="input_vpc_peering_connection_id"></a> [vpc\_peering\_connection\_id](#input\_vpc\_peering\_connection\_id) | ID of the VPC Peering Connection | `string` | `null` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_id"></a> [id](#output\_id) | The ID of the route. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
