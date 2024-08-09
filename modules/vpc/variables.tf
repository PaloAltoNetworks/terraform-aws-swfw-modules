variable "name" {
  description = "Name of the VPC to create or use."
  type        = string
}

variable "region" {
  description = "AWS region."
  type        = string
}

variable "create_vpc" {
  description = "When set to `true` inputs are used to create a VPC, otherwise - to get data about an existing one."
  default     = true
  type        = bool
}

variable "tags" {
  description = "Optional map of arbitrary tags to apply to all the created resources."
  default     = {}
  type        = map(string)
}

variable "vpc_tags" {
  description = "Optional map of arbitrary tags to apply to VPC resource."
  default     = {}
  type        = map(string)
}

variable "cidr_block" {
  description = <<-EOF
  Object containing the IPv4 and IPv6 CIDR blocks to assign to a new VPC.

  Properties:
  - `ipv4`                  - (`string`, optional) the IPv4 CIDR block to assign to the VPC.
  - `secondary_ipv4`        - (`list(string)`, optional, defaults to `[]`) a list of secondary IPv4 CIDR blocks to assign to VPC.
  - `assign_generated_ipv6` - (`bool`, optional, defaults to `false`) a boolean flag to assign AWS-provided /56 IPv6 CIDR block.

  Example:
  ```hcl
  cidr_block = {
    ipv4 = "10.0.0.0/16"
  }
  ```
  EOF
  type = object({
    ipv4                  = optional(string)
    secondary_ipv4        = optional(list(string), [])
    assign_generated_ipv6 = optional(bool, false)
  })
  validation { # ipv4
    condition     = can(regex("^(\\d{1,3}\\.){3}\\d{1,3}\\/[12]?[0-9]$", var.cidr_block.ipv4))
    error_message = <<-EOF
    The CIDR block should be in CIDR notation, with the maximum subnet of /28.
    EOF
  }
  validation { # secondary_ipv4
    condition = alltrue([
      for v in var.cidr_block.secondary_ipv4 :
      can(regex("^(\\d{1,3}\\.){3}\\d{1,3}\\/[12]?[0-9]$", v))
    ])
    error_message = <<-EOF
    All items in secondary_ipv4 should be in CIDR notation, with the maximum subnet of /28.
    EOF
  }
}

variable "options" {
  description = <<-EOF
  Object containing the VPC options.

  Properties:
  - `enable_dns_support`      - (`bool`, optional, defaults to `true`) a boolean flag to enable/disable DNS support in the VPC.
  - `enable_dns_hostnames`    - (`bool`, optional, defaults to `false`) a boolean flag to enable/disable DNS hostnames in the VPC.
  - `create_dhcp_options`     - (`bool`, optional, defaults to `false`) a boolean flag to create a DHCP options set.
  - `domain_name`             - (`string`, optional) the DNS name for the DHCP options set.
  - `domain_name_servers`     - (`list(string)`, optional, defaults to `[]`) a list of DNS server addresses for DHCP options set.
  - `ntp_servers`             - (`list(string)`, optional, defaults to `[]`) a list of NTP server addresses for DHCP options set.
  - `instance_tenancy`        - (`string`, optional) the tenancy of instances launched into the VPC.
  - `map_public_ip_on_launch` - (`bool`, optional, defaults to `false`) a boolean flag to enable/disable public IP on launch.
  - `propagating_vgws`        - (`list(string)`, optional, defaults to `[]`) a list of VGWs to propagate routes to.

  Example:
  ```hcl
  options = {
    enable_dns_support   = true
    enable_dns_hostnames = true
    create_dhcp_options  = true
  }
  ```
  EOF
  type = object({
    enable_dns_support      = optional(bool, true)
    enable_dns_hostnames    = optional(bool, false)
    create_dhcp_options     = optional(bool, false)
    domain_name             = optional(string)
    domain_name_servers     = optional(list(string), [])
    ntp_servers             = optional(list(string), [])
    instance_tenancy        = optional(string, "default")
    map_public_ip_on_launch = optional(bool, false)
    propagating_vgws        = optional(list(string), [])
  })
  validation { # instance_tenancy
    condition     = contains(["default", "dedicated"], var.options.instance_tenancy)
    error_message = <<-EOF
    The `instance_tenancy` property should be one of default or dedicated.
    EOF
  }
}

variable "internet_gateway" {
  description = <<-EOF
  Object containing the Internet Gateway options.

  Properties:
  - `create`       - (`bool`, optional, defaults to `true`) a boolean flag to create an Internet Gateway.
  - `use_existing` - (`bool`, optional, defaults to `false`) a boolean flag to use an existing Internet Gateway.
  - `name`         - (`string`, optional) the name of the Internet Gateway to create or use.
  - `route_table`  - (`string`, optional) the name of the route table for the Internet Gateway.

  Example:
  ```hcl
  internet_gateway = {
    create = true
  }
  ```
  EOF
  default = {
    create = true
  }
  type = object({
    create       = optional(bool, true)
    use_existing = optional(bool, false)
    name         = optional(string)
    route_table  = optional(string)
  })
}

variable "vpn_gateway" {
  description = <<-EOF
  Object containing the VPN Gateway options.

  Properties:
  - `create`          - (`bool`, optional, defaults to `false`) a boolean flag to create a VPN Gateway.
  - `amazon_side_asn` - (`string`, optional) the ASN for the Amazon side of the gateway.
  - `name`            - (`string`, optional) the name of the VPN Gateway to create.
  - `route_table`     - (`string`, optional) the name of the route table for VPN Gateway.

  Example:
  ```hcl
  vpn_gateway = {
    create = false
  }
  ```
  EOF
  default = {
    create = false
  }
  type = object({
    create          = optional(bool, false)
    amazon_side_asn = optional(string)
    name            = optional(string)
    route_table     = optional(string)
  })
}

variable "subnets" {
  description = <<EOF
  The `subnets` variable is a map of objects, where each object represents an AWS Subnet.

  Properties:
  - `az`                      - (`string`) the availability zone for the subnet.
  - `cidr_block`              - (`string`) the CIDR block for the subnet.
  - `ipv6_cidr_block`         - (`string`, optional) the IPv6 CIDR block for the subnet.
  - `ipv6_index`              - (`number`, optional) the index of the IPv6 CIDR block.
  - `subnet_group`            - (`string`) the name of the subnet group.
  - `name`                    - (`string`) the name of the subnet.
  - `nacl`                    - (`string`, optional) the name of the NACL to associate with the subnet.
  - `create_subnet`           - (`bool`, optional, defaults to `true`) a boolean flag to create a subnet.
  - `create_route_table`      - (`bool`, optional, defaults to `true`) a boolean flag to create a route table.
  - `route_table_name`        - (`string`, optional) the name of the route table.
  - `existing_route_table_id` - (`string`, optional) the ID of the existing route table.
  - `associate_route_table`   - (`bool`, optional, defaults to `true`) a boolean flag to associate a route table.
  - `tags`                    - (`map(string)`, optional) a map of arbitrary tags to apply to the subnet.

  Example:
  ```hcl
  subnets = {
    app1_vma    = { az = "a", cidr_block = "10.104.0.0/24", subnet_group = "app1_vm", name = "app1_vm1" }
    app1_vmb    = { az = "b", cidr_block = "10.104.128.0/24", subnet_group = "app1_vm", name = "app1_vm2" }
    app1_lba    = { az = "a", cidr_block = "10.104.2.0/24", subnet_group = "app1_lb", name = "app1_lb1" }
    app1_lbb    = { az = "b", cidr_block = "10.104.130.0/24", subnet_group = "app1_lb", name = "app1_lb2" }
    app1_gwlbea = { az = "a", cidr_block = "10.104.3.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe1" }
    app1_gwlbeb = { az = "b", cidr_block = "10.104.131.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe2" }
  }
  ```
  EOF
  type = map(object({
    az                      = string
    cidr_block              = string
    ipv6_cidr_block         = optional(string)
    ipv6_index              = optional(number)
    subnet_group            = string
    name                    = string
    nacl                    = optional(string)
    create_subnet           = optional(bool, true)
    create_route_table      = optional(bool, true)
    route_table_name        = optional(string)
    existing_route_table_id = optional(string)
    associate_route_table   = optional(bool, true)
    tags                    = optional(map(string))
  }))
  validation { # cidr_block
    condition = alltrue(flatten([
      for _, subnet in var.subnets :
      can(regex("^(\\d{1,3}\\.){3}\\d{1,3}\\/[123]?[0-9]$", subnet.cidr_block))
    ]))
    error_message = <<-EOF
    The CIDR block should be in CIDR notation.
    EOF
  }
  validation { # az
    condition = alltrue(flatten([
      for _, subnet in var.subnets :
      can(regex("^[a-z]$", subnet.az))
    ]))
    error_message = <<-EOF
    The availability zone should be a single lowercase letter.
    EOF
  }
}

variable "nacls" {
  description = <<EOF
  The `nacls` variable is a map of objects, where each object represents an AWS NACL.

  Properties:
  - `name`  - (`string`) the name of the NACL.
  - `rules` - (`map(object)`) a map of objects representing the NACL rules. The key of each entry acts as the name of the rule and
      needs to be unique across all rules in the NACL. List of attributes available to define a NACL rule:
      - `rule_number` - (`number`) the rule number for the NACL rule.
      - `type`        - (`string`) specifies if rule will be evaluated on ingress (inbound) or egress (outbound) traffic.
      - `protocol`    - (`string`) the protocol. If -1, it means all protocols.
      - `action`      - (`string`) the action to take. Valid values are `allow` and `deny`.
      - `cidr_block`  - (`string`) the CIDR block to match. If not specified, it means all IP addresses.
      - `from_port`   - (`string`, optional) the from port.
      - `to_port`     - (`string`, optional) the to port.

  Example:
  ```
  nacls = {
    trusted_path_monitoring = {
      name = "trusted-path-monitoring"
      rules = {
        allow_other_outbound = {
          rule_number = 200
          type        = "egress"
          protocol    = "-1"
          action      = "allow"
          cidr_block  = "0.0.0.0/0"
        }
        allow_inbound = {
          rule_number = 300
          type        = "ingress"
          protocol    = "-1"
          action      = "allow"
          cidr_block  = "0.0.0.0/0"
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name = string
    rules = map(object({
      rule_number = number
      type        = string
      protocol    = string
      action      = string
      cidr_block  = string
      from_port   = optional(string)
      to_port     = optional(string)
    }))
  }))
  validation { # type
    condition = alltrue(flatten([
      for _, nacl in var.nacls : [
        for _, rule in nacl.rules :
        contains(["ingress", "egress"], rule.type)
    ]]))
    error_message = <<-EOF
    The rule type should be either ingress or egress.
    EOF
  }
  validation { # action
    condition = alltrue(flatten([
      for _, nacl in var.nacls : [
        for _, rule in nacl.rules :
        contains(["allow", "deny"], rule.action)
    ]]))
    error_message = <<-EOF
    The rule action should be either allow or deny.
    EOF
  }
  validation { # cidr_block
    condition = alltrue(flatten([
      for _, nacl in var.nacls : [
        for _, rule in nacl.rules :
        can(regex("^(\\d{1,3}\\.){3}\\d{1,3}\\/[123]?[0-9]$", rule.cidr_block))
    ]]))
    error_message = <<-EOF
    The CIDR block should be in CIDR notation.
    EOF
  }
  validation { # protocol
    condition = alltrue(flatten([
      for _, nacl in var.nacls : [
        for _, rule in nacl.rules :
        can(regex("^(tcp|udp|icmp|-1)$", rule.protocol))
    ]]))
    error_message = <<-EOF
    The protocol should be either tcp, udp, icmp or -1.
    EOF
  }
}

variable "security_groups" {
  description = <<EOF
  The `security_groups` variable is a map of object, where each object represents an AWS Security Group.

  Properties:
  - `name`        - (`string`) the name of the security group.
  - `description` - (`string`, optional) the description of the security group.
  - `rules`       - (`map(object)`) a map of objects representing the security group rules. The key of each entry acts
      as the name of the rule and needs to be unique across all rules in the security group.
      List of attributes available to define a security group rule:
      - `description`            - (`string`) the description of the rule.
      - `type`                   - (`string`) specifies if rule will be evaluated on ingress or egress traffic.
      - `from_port`              - (`string`) the from port.
      - `to_port`                - (`string`) the to port.
      - `protocol`               - (`string`) the protocol.
      - `cidr_blocks`            - (`list(string)`) a list of CIDR blocks to allow traffic from/to.
      - `ipv6_cidr_blocks`       - (`list(string)`, optional) a list of IPv6 CIDR blocks to allow traffic from/to.
      - `prefix_list_ids`        - (`list(string)`, optional) a list of prefix list IDs to allow traffic from/to.
      - `self`                   - (`bool`, optional, defaults to `false`) a boolean flag to allow traffic from/to the SG itself.
      - `source_security_groups` - (`list(string)`, optional) a list of security group IDs to allow traffic from/to.

  Example:
  ```
  security_groups = {
    vmseries_mgmt = {
      name = "vmseries_mgmt"
      rules = {
        all_outbound = {
          description = "Permit All traffic outbound"
          type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
        https = {
          description = "Permit HTTPS"
          type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
        }
        ssh = {
          description = "Permit SSH"
          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
          cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
        }
        panorama_ssh = {
          description = "Permit Panorama SSH (Optional)"
          type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
          cidr_blocks = ["10.0.0.0/8"]
        }
      }
    }
  }
  ```
  EOF

  default = {}
  type = map(object({
    name        = string
    description = optional(string, "Security group managed by Terraform")
    rules = map(object({
      description            = string
      type                   = string
      from_port              = string
      to_port                = string
      protocol               = string
      cidr_blocks            = list(string)
      ipv6_cidr_blocks       = optional(list(string))
      prefix_list_ids        = optional(list(string))
      self                   = optional(bool, false)
      source_security_groups = optional(list(string))
    }))
  }))
  validation { # cidr_block
    condition = alltrue(flatten([
      for _, security_group in var.security_groups : [
        for _, rule in security_group.rules : [
          for _, cidr_block in rule.cidr_blocks :
          can(regex("^(\\d{1,3}\\.){3}\\d{1,3}\\/[123]?[0-9]$", cidr_block))
    ]]]))
    error_message = <<-EOF
    The CIDR block should be in CIDR notation.
    EOF
  }
  validation { # protocol
    condition = alltrue(flatten([
      for _, security_group in var.security_groups : [
        for _, rule in security_group.rules :
        can(regex("^(tcp|udp|icmp|-1)$", rule.protocol))
    ]]))
    error_message = <<-EOF
    The protocol should be either tcp, udp, icmp or -1.
    EOF
  }
}
