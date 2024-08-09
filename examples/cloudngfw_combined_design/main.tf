data "aws_caller_identity" "current" {}

### VPCS ###

module "vpc" {
  source = "../../modules/vpc"

  for_each = var.vpcs

  region          = var.region
  name            = "${var.name_prefix}${each.value.name}"
  cidr_block      = each.value.cidr_block
  subnets         = each.value.subnets
  nacls           = each.value.nacls
  security_groups = each.value.security_groups

  options = {
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"
  }
}

### ROUTES ###

locals {
  # Flatten the VPCs and their routes into a list of maps, each containing the VPC name, subnet name, and route details.
  # In TFVARS there is no possibility to define ID of the next hop, so we need to use the key of the next hop e.g.name =
  #
  #    tgw_default = {
  #      vpc           = "security_vpc"
  #      subnet_group  = "tgw_attach"
  #      to_cidr       = "0.0.0.0/0"
  #      next_hop_key  = "security_gwlb_outbound"
  #      next_hop_type = "gwlbe_endpoint"
  #    }
  #
  # Value of `next_hop_type` defines the type of the next hop. It can be one of the following:
  # - internet_gateway
  # - nat_gateway
  # - transit_gateway_attachment
  # - gwlbe_endpoint
  #
  # If more next hop types are needed, they can be added below.
  #
  # Value of `next_hop_key` is the key of the next hop.
  # It is used to reference the next hop in the module that manages it.
  #
  # Value of `to_cidr` is the CIDR of the destination.

  vpc_routes_with_next_hop_map = flatten(concat([
    for vk, vv in var.vpcs : [
      for rk, rv in vv.routes : {
        vpc           = rv.vpc
        subnet_group  = rv.subnet_group
        to_cidr       = rv.to_cidr
        next_hop_type = rv.next_hop_type
        next_hop_map = {
          "internet_gateway"           = try(module.vpc[rv.next_hop_key].igw_as_next_hop_set, null)
          "nat_gateway"                = try(module.natgw_set[rv.next_hop_key].next_hop_set, null)
          "transit_gateway_attachment" = try(module.transit_gateway_attachment[rv.next_hop_key].next_hop_set, null)
          "gwlbe_endpoint"             = try(module.gwlbe_endpoint[rv.next_hop_key].next_hop_set, null)
        }
      }
  ]]))
  vpc_routes = {
    for route in local.vpc_routes_with_next_hop_map : "${route.vpc}-${route.subnet_group}-${route.to_cidr}" => {
      vpc          = route.vpc
      subnet_group = route.subnet_group
      to_cidr      = route.to_cidr
      next_hop_set = lookup(route.next_hop_map, route.next_hop_type, null)
    }
  }
}

module "vpc_routes" {
  source = "../../modules/vpc_route"

  for_each = local.vpc_routes

  route_table_ids = { for k, v in module.vpc[each.value.vpc].route_tables : v.az => v.id if v.subnet_group == each.value.subnet_group }
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}

### NATGW ###

module "natgw_set" {
  source = "../../modules/nat_gateway_set"

  for_each = var.natgws

  subnets = { for k, v in module.vpc[each.value.vpc].subnets : v.az => v if v.subnet_group == each.value.subnet_group }
}

### TGW ###

module "transit_gateway" {
  source = "../../modules/transit_gateway"

  create       = var.tgw.create
  id           = var.tgw.id
  name         = "${var.name_prefix}${var.tgw.name}"
  asn          = var.tgw.asn
  route_tables = var.tgw.route_tables
}

### TGW ATTACHMENTS ###

module "transit_gateway_attachment" {
  source = "../../modules/transit_gateway_attachment"

  for_each = var.tgw.attachments

  name                        = "${var.name_prefix}${each.value.name}"
  vpc_id                      = module.vpc[each.value.vpc].id
  subnets                     = { for k, v in module.vpc[each.value.vpc].subnets : k => v if v.subnet_group == each.value.subnet_group }
  transit_gateway_route_table = module.transit_gateway.route_tables[each.value.route_table]
  propagate_routes_to = {
    to1 = module.transit_gateway.route_tables[each.value.propagate_routes_to].id
  }
}

resource "aws_ec2_transit_gateway_route" "from_spokes_to_security" {
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_spoke_vpc"].id
  transit_gateway_attachment_id  = module.transit_gateway_attachment["security"].attachment.id
  destination_cidr_block         = "0.0.0.0/0"
  blackhole                      = false
}

### CloudNGFW ###

module "cloudngfw" {
  source = "../../modules/cloudngfw"

  for_each = var.cloudngfws

  name           = "${var.name_prefix}${each.value.name}"
  subnets        = { for k, v in module.vpc[each.value.vpc].subnets : "${var.region}${v.az}" => v if v.subnet_group == each.value.subnet_group }
  vpc_id         = module.vpc[each.value.vpc].id
  rulestack_name = "${var.name_prefix}${each.value.name}"
  description    = each.value.description
  security_rules = each.value.security_rules
  log_profiles   = each.value.log_profiles
  profile_config = each.value.profile_config
}

### GWLB ENDPOINTS ###

module "gwlbe_endpoint" {
  source = "../../modules/gwlb_endpoint_set"

  for_each = var.gwlb_endpoints

  name              = "${var.name_prefix}${each.value.name}"
  gwlb_service_name = module.cloudngfw[each.value.cloudngfw].cloudngfw_service_name
  vpc_id            = module.vpc[each.value.vpc].id
  subnets           = { for k, v in module.vpc[each.value.vpc].subnets : v.az => v if v.subnet_group == each.value.subnet_group }
  delay             = each.value.delay

  act_as_next_hop_for = each.value.act_as_next_hop ? {
    "from-igw-to-lb" = {
      route_table_id = module.vpc[each.value.vpc].internet_gateway_route_table.id
      to_subnets     = { for k, v in module.vpc[each.value.from_igw_to_vpc].subnets : v.az => v if v.subnet_group == each.value.from_igw_to_subnet_group }
    }
    # The routes in this section are special in that they are on the "edge", that is they are part of an IGW route table,
    # and AWS allows their destinations to only be:
    #     - The entire IPv4 or IPv6 CIDR block of your VPC. (Not interesting, as we always want AZ-specific next hops.)
    #     - The entire IPv4 or IPv6 CIDR block of a subnet in your VPC. (This is used here.)
    # Source: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table
  } : {}
}

### SPOKE VM INSTANCES ####

data "aws_ami" "this" {
  most_recent = true # newest by time, not by version number

  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }

  owners = ["137112412989"]
}

data "aws_ebs_default_kms_key" "current" {
}

data "aws_kms_alias" "current_arn" {
  name = data.aws_ebs_default_kms_key.current.key_arn
}

resource "aws_iam_role" "spoke_vm_ec2_iam_role" {
  name               = "${var.name_prefix}spoke_vm"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Principal": {"Service": "ec2.amazonaws.com"}
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "spoke_vm_iam_instance_policy" {
  role       = aws_iam_role.spoke_vm_ec2_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "spoke_vm_iam_instance_profile" {

  name = "${var.name_prefix}spoke_vm_instance_profile"
  role = aws_iam_role.spoke_vm_ec2_iam_role.name

}

resource "aws_instance" "spoke_vms" {
  for_each = var.spoke_vms

  ami                    = data.aws_ami.this.id
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  subnet_id              = module.vpc[each.value.vpc].subnets["${each.value.subnet_group}${each.value.az}"].id
  vpc_security_group_ids = [module.vpc[each.value.vpc].security_group_ids[each.value.security_group]]
  tags                   = merge({ Name = "${var.name_prefix}${each.key}" }, var.tags)
  iam_instance_profile   = aws_iam_instance_profile.spoke_vm_iam_instance_profile.name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_kms_alias.current_arn.target_key_arn
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = <<EOF
  #!/bin/bash
  until yum update -y; do echo "Retrying"; sleep 5; done
  until yum install -y httpd; do echo "Retrying"; sleep 5; done
  systemctl start httpd
  systemctl enable httpd
  usermod -a -G apache ec2-user
  chown -R ec2-user:apache /var/www
  chmod 2775 /var/www
  find /var/www -type d -exec chmod 2775 {} \;
  find /var/www -type f -exec chmod 0664 {} \;
  EOF
}

### SPOKE INBOUND APPLICATION LOAD BALANCER ###

module "public_alb" {
  source = "../../modules/alb"

  for_each = var.spoke_albs

  lb_name         = "${var.name_prefix}${each.key}"
  subnets         = { for k, v in module.vpc[each.value.vpc].subnets : k => { id = v.id } if v.subnet_group == each.value.subnet_group }
  vpc_id          = module.vpc[each.value.vpc].id
  security_groups = [module.vpc[each.value.vpc].security_group_ids[each.value.security_groups]]
  rules           = each.value.rules
  targets         = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].private_ip }

  tags = var.tags
}

### SPOKE INBOUND NETWORK LOAD BALANCER ###

module "public_nlb" {
  source = "../../modules/nlb"

  for_each = var.spoke_nlbs

  name        = "${var.name_prefix}${each.key}"
  internal_lb = false
  subnets     = { for k, v in module.vpc[each.value.vpc].subnets : k => { id = v.id } if v.subnet_group == each.value.subnet_group }
  vpc_id      = module.vpc[each.value.vpc].id

  balance_rules = {
    "SSH-traffic" = {
      protocol    = "TCP"
      port        = "22"
      target_type = "instance"
      stickiness  = true
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
  }

  tags = var.tags
}