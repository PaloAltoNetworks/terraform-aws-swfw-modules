locals {
  vpc              = var.create_vpc ? aws_vpc.this[0] : data.aws_vpc.this[0]
  internet_gateway = var.internet_gateway.create ? aws_internet_gateway.this[0] : var.internet_gateway.use_existing ? data.aws_internet_gateway.this[0] : null
  subnets          = { for k, v in var.subnets : k => v.create_subnet ? aws_subnet.this[k] : data.aws_subnet.this[k] }
  route_tables     = { for k, v in var.subnets : k => v.create_route_table ? aws_route_table.this[k] : data.aws_route_table.this[k] }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
data "aws_vpc" "this" {
  count = var.create_vpc == false ? 1 : 0

  tags = { Name = var.name }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "this" {
  count = var.create_vpc ? 1 : 0

  cidr_block                       = var.cidr_block.ipv4
  assign_generated_ipv6_cidr_block = var.cidr_block.assign_generated_ipv6
  enable_dns_support               = var.options.enable_dns_support
  enable_dns_hostnames             = var.options.enable_dns_hostnames
  instance_tenancy                 = var.options.instance_tenancy

  tags = merge(var.tags, var.vpc_tags, { Name = var.name })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_ipv4_cidr_block_association
resource "aws_vpc_ipv4_cidr_block_association" "this" {
  for_each = { for _, v in var.cidr_block.secondary_ipv4 : v => "ipv4" }

  vpc_id     = local.vpc.id
  cidr_block = each.key
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options
resource "aws_vpc_dhcp_options" "this" {
  count = var.options.create_dhcp_options ? 1 : 0

  domain_name         = var.options.domain_name
  domain_name_servers = var.options.domain_name_servers
  ntp_servers         = var.options.ntp_servers

  tags = merge(var.tags, var.vpc_tags, { Name = var.name })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_dhcp_options_association
resource "aws_vpc_dhcp_options_association" "this" {
  count = var.options.create_dhcp_options ? 1 : 0

  vpc_id          = local.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.this[0].id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/internet_gateway
data "aws_internet_gateway" "this" {
  count = var.internet_gateway.create == false && var.internet_gateway.use_existing ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [local.vpc.id]
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "this" {
  count = var.internet_gateway.create ? 1 : 0

  vpc_id = local.vpc.id

  tags = merge(var.tags, { Name = coalesce(var.internet_gateway.name, "${var.name}-igw") })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "igw" {
  count = var.internet_gateway.create ? 1 : 0

  vpc_id = local.vpc.id

  tags = merge(var.tags, { Name = coalesce(var.internet_gateway.route_table, "${var.name}-igw") })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "igw" {
  count = var.internet_gateway.create ? 1 : 0

  route_table_id = aws_route_table.from_igw[0].id
  gateway_id     = local.internet_gateway.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpn_gateway
resource "aws_vpn_gateway" "this" {
  count = var.vpn_gateway.create ? 1 : 0

  vpc_id          = local.vpc.id
  amazon_side_asn = var.vpn_gateway.amazon_side_asn

  tags = merge(var.tags, { Name = coalesce(var.vpn_gateway.name, "${var.name}-vgw") })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "vgw" {
  count = var.vpn_gateway.create ? 1 : 0

  vpc_id = local.vpc.id

  tags = merge(var.tags, { Name = coalesce(var.vpn_gateway.route_table, "${var.name}-vgw") })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "from_vgw" {
  count = var.vpn_gateway.create ? 1 : 0

  gateway_id     = aws_vpn_gateway.this[0].id
  route_table_id = aws_route_table.from_vgw[0].id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet
data "aws_subnet" "this" {
  for_each = { for k, v in var.subnets : k => v if v.create_subnet == false }

  vpc_id = local.vpc.id

  tags = { Name = each.value.name }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet
resource "aws_subnet" "this" {
  for_each = { for k, v in var.subnets : k => v if v.create_subnet }

  cidr_block              = each.value.cidr_block
  ipv6_cidr_block         = try(cidrsubnet(local.vpc.ipv6_cidr_block, 8, each.value.ipv6_index), each.value.ipv6_cidr_block)
  availability_zone       = "${var.region}${each.value.az}"
  vpc_id                  = local.vpc.id
  map_public_ip_on_launch = var.options.map_public_ip_on_launch

  tags = merge(var.tags, each.value.tags, { Name = each.value.name })

  depends_on = [
    aws_vpc_ipv4_cidr_block_association.this
  ]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route_table
data "aws_route_table" "this" {
  for_each = { for k, v in var.subnets : k => v if v.create_route_table == false }

  vpc_id         = local.vpc.id
  route_table_id = each.value.existing_route_table_id

  tags = { Name = coalesce(each.value.route_table_name, each.value.name) }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "this" {
  for_each = { for k, v in var.subnets : k => v if v.create_route_table }

  vpc_id           = local.vpc.id
  propagating_vgws = var.options.propagating_vgws

  tags = merge(var.tags, each.value.tags, { Name = coalesce(each.value.route_table_name, each.value.name) })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "this" {
  for_each = { for k, v in var.subnets : k => v if v.associate_route_table }

  subnet_id      = local.subnets[each.key].id
  route_table_id = local.route_tables[each.key].id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "shared" {
  for_each = { for k, v in var.shared_route_tables : k => v }

  vpc_id           = local.vpc.id
  propagating_vgws = var.options.propagating_vgws

  tags = merge(var.tags, each.value.tags, { Name = each.value.name })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "shared" {
  for_each = { for k, v in var.subnets : k => v if try(length(v.shared_route_table) > 0, false) }

  subnet_id      = local.subnets[each.key].id
  route_table_id = aws_route_table.shared[each.value.shared_route_table].id

  depends_on = [aws_route_table.shared]
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl
resource "aws_network_acl" "this" {
  for_each = var.nacls

  vpc_id = local.vpc.id

  tags = merge(var.tags, { Name = each.value.name })
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_rule
resource "aws_network_acl_rule" "this" {
  for_each = {
    for item in flatten([
      for key_nacl, nacl in var.nacls : [
        for key_rule, rule in nacl.rules : merge(rule, {
          nacl = key_nacl
          rule = key_rule
        })
      ]
    ]) : "${item.nacl}_${item.rule}" => item
  }
  network_acl_id = aws_network_acl.this[each.value.nacl].id
  rule_number    = each.value.rule_number
  egress         = each.value.type == "egress"
  protocol       = each.value.protocol
  rule_action    = each.value.action
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/network_acl_association
resource "aws_network_acl_association" "main" {
  for_each       = { for k, v in var.subnets : k => v if v.nacl != null }
  network_acl_id = aws_network_acl.this[each.value.nacl].id
  subnet_id      = local.subnets[each.key].id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = each.value.name
  description = each.value.description
  vpc_id      = local.vpc.id

  dynamic "ingress" {
    for_each = [
      for rule in each.value.rules : rule if rule.type == "ingress"
    ]

    content {
      from_port        = ingress.value.from_port
      to_port          = ingress.value.to_port
      protocol         = ingress.value.protocol
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
      prefix_list_ids  = ingress.value.prefix_list_ids
      self             = ingress.value.self
      security_groups  = ingress.value.source_security_groups
      description      = ingress.value.description
    }
  }

  dynamic "egress" {
    for_each = [
      for rule in each.value.rules : rule if rule.type == "egress"
    ]

    content {
      from_port        = egress.value.from_port
      to_port          = egress.value.to_port
      protocol         = egress.value.protocol
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.ipv6_cidr_blocks
      prefix_list_ids  = egress.value.prefix_list_ids
      description      = egress.value.description
    }
  }

  tags = merge(var.tags, { Name = each.value.name })

  lifecycle {
    create_before_destroy = true
  }
}
