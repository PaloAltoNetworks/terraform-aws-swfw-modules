
locals {
  transit_gateway_attachment = var.create ? aws_ec2_transit_gateway_vpc_attachment.this[0] : data.aws_ec2_transit_gateway_vpc_attachment.this[0]
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = var.create ? 1 : 0

  vpc_id                                          = var.vpc_id
  subnet_ids                                      = [for _, subnet in var.subnets : subnet.id]
  transit_gateway_id                              = var.transit_gateway_route_table.transit_gateway_id
  transit_gateway_default_route_table_association = false
  transit_gateway_default_route_table_propagation = false
  appliance_mode_support                          = var.appliance_mode_support
  dns_support                                     = var.dns_support
  ipv6_support                                    = var.ipv6_support
  tags                                            = merge(var.tags, var.name != null ? { Name = var.name } : {})
}

data "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count = var.create == false ? 1 : 0

  # ID of an existing transit gateway attachment. By default set to `null` hence can be referenced directly.
  id = var.id
  # Filtering existing transit gateway attachment by name, only in case no ID was provided.
  dynamic "filter" {
    for_each = var.id == null ? [1] : []
    content {
      name   = "tag:Name"
      values = [var.name]
    }
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "this" {
  count = var.create ? 1 : 0

  transit_gateway_attachment_id  = local.transit_gateway_attachment.id
  transit_gateway_route_table_id = var.transit_gateway_route_table.id
}

resource "aws_ec2_transit_gateway_route_table_propagation" "this" {
  for_each = var.create ? var.propagate_routes_to : {}

  transit_gateway_attachment_id  = local.transit_gateway_attachment.id
  transit_gateway_route_table_id = each.value
}
