variable "route_table_id" {
  description = "ID of the route table"
  type        = string
}

variable "to_cidr" {
  description = "The CIDR to match the packet's destination field. If they match, the route can be used for the packet. For example \"0.0.0.0/0\"."
  type        = string
}

variable "destination_type" {
  description = "Type of destination: \"ipv4\", \"ipv6\" or \"mpl\"."
  default     = "ipv4"
  type        = string
}

variable "managed_prefix_list_id" {
  description = "ID of managed prefix list, which is going to be set as destination in route"
  default     = null
  type        = string
}

variable "core_network_arn" {
  description = "The ARN of the core network"
  default     = null
  type        = string
}

variable "next_hop_type" {
  description = "Type of next hop."
  type        = string
  validation {
    condition     = can(regex("^(carrier_gateway|internet_gateway|vpn_gateway|transit_gateway|nat_gateway|network_interface|vpc_endpoint|gwlbe_endpoint|vpc_peering_connection|egress_only_gateway|local_gateway)$", var.next_hop_type))
    error_message = "Invalid next_hop_type. Possible values: carrier_gateway, internet_gateway, vpn_gateway, transit_gateway, nat_gateway, network_interface, vpc_endpoint, gwlbe_endpoint, vpc_peering_connection, egress_only_gateway, local_gateway."
  }
}

variable "carrier_gateway_id" {
  description = "ID of the carrier gateway"
  default     = null
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  default     = null
  type        = string
}

variable "transit_gateway_id" {
  description = "ID of the transit gateway"
  default     = null
  type        = string
}

variable "nat_gateway_id" {
  description = "ID of the NAT Gateway"
  default     = null
  type        = string
}

variable "network_interface_id" {
  description = "ID of the network interface"
  default     = null
  type        = string
}

variable "vpc_endpoint_id" {
  description = "ID of the VPC Endpoint"
  default     = null
  type        = string
}

variable "vpc_peering_connection_id" {
  description = "ID of the VPC Peering Connection"
  default     = null
  type        = string
}

variable "egress_only_gateway_id" {
  description = "ID of the Egress Only Internet Gateway"
  default     = null
  type        = string
}

variable "local_gateway_id" {
  description = "ID of the Local Gateway"
  default     = null
  type        = string
}
