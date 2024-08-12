# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route
resource "aws_route" "this" {
  route_table_id              = var.route_tables[var.az]
  destination_cidr_block      = var.destination_type == "ipv4" ? var.to_cidr : null
  destination_ipv6_cidr_block = var.destination_type == "ipv6" ? var.to_cidr : null
  destination_prefix_list_id  = var.destination_type == "mpl" ? var.managed_prefix_list_id : null
  core_network_arn            = var.core_network_arn

  carrier_gateway_id        = var.next_hop_type == "carrier_gateway" ? var.carrier_gateway_id : null
  transit_gateway_id        = var.next_hop_type == "transit_gateway" ? var.transit_gateway_id : null
  gateway_id                = var.next_hop_type == "internet_gateway" || var.next_hop_type == "vpn_gateway" ? var.internet_gateway_id : null
  nat_gateway_id            = var.next_hop_type == "nat_gateway" ? var.nat_gateways[var.az] : null
  network_interface_id      = var.next_hop_type == "interface" ? var.network_interfaces[var.az] : null
  vpc_endpoint_id           = var.next_hop_type == "vpc_endpoint" || var.next_hop_type == "gwlbe_endpoint" ? var.vpc_endpoints[var.az] : null
  vpc_peering_connection_id = var.next_hop_type == "vpc_peer" ? var.vpc_peering_connection_id : null
  egress_only_gateway_id    = var.next_hop_type == "egress_only_gateway" ? var.egress_only_gateway_id : null # for non-SNAT IPv6 egress only
  local_gateway_id          = var.next_hop_type == "local_gateway" ? var.local_gateway_id : null             # for an AWS Outpost only
}
