output "attachment" {
  description = "The entire `aws_ec2_transit_gateway_vpc_attachment` object."
  value       = local.transit_gateway_attachment
}

output "subnets" {
  description = "Same as the input `subnets`. Intended to be used as a dependency."
  value       = contains(local.transit_gateway_attachment.subnet_ids, "!") == false ? var.subnets : null
}

output "next_hop_set" {
  description = <<-EOF
  The Next Hop Set object, useful as an input to the `vpc_route` module. The intention would
  be to route traffic from several subnets to the Transit Gateway. Example:

  ```
  next_hop_set = {
    ids = {}
    id   = "tgw-attach-123"
    type = "transit_gateway"
  }
  ```
  EOF
  value = {
    type = "transit_gateway"
    id   = local.transit_gateway_attachment.transit_gateway_id
    ids  = {}
  }
}
