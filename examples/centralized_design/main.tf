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

module "vpc_routes" {
  source = "../../modules/vpc_route"

  for_each = merge([
    for vk, vv in var.vpcs : {
      for rk, rv in vv.routes : "${vk}${rk}" => merge(rv, { vpc = vk })
    }
  ]...)

  route_table_id = module.vpc[each.value.vpc].route_tables[each.value.route_table].id
  to_cidr        = each.value.to_cidr
  next_hop_type  = each.value.next_hop_type

  transit_gateway_id  = each.value.next_hop_type == "transit_gateway" ? module.transit_gateway.transit_gateway.id : null
  internet_gateway_id = each.value.next_hop_type == "internet_gateway" ? module.vpc[each.value.next_hop_key].internet_gateway.id : null
  nat_gateway_id      = each.value.next_hop_type == "nat_gateway" ? module.natgw_set[each.value.next_hop_key].next_hop_set.ids[each.value.az] : null
  vpc_endpoint_id     = each.value.next_hop_type == "gwlbe_endpoint" ? module.gwlbe_endpoint[each.value.next_hop_key].next_hop_set.ids[each.value.az] : null
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

resource "aws_ec2_transit_gateway_route" "from_security_to_panorama" {
  count                          = var.panorama_attachment.transit_gateway_attachment_id != null ? 1 : 0
  transit_gateway_route_table_id = module.transit_gateway.route_tables["from_security_vpc"].id
  transit_gateway_attachment_id  = var.panorama_attachment.transit_gateway_attachment_id
  destination_cidr_block         = var.panorama_attachment.vpc_cidr
  blackhole                      = false
}

### GWLB ###

module "gwlb" {
  source = "../../modules/gwlb"

  for_each = var.gwlbs

  name    = "${var.name_prefix}${each.value.name}"
  vpc_id  = module.vpc[each.value.vpc].id
  subnets = { for k, v in module.vpc[each.value.vpc].subnets : v.az => v if v.subnet_group == each.value.subnet_group }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => {
    gwlb = vmseries.common.gwlb
    id   = module.vmseries["${vmseries.group}-${vmseries.instance}"].instance.id
  } }

  target_group_arn = module.gwlb[each.value.gwlb].target_group.arn
  target_id        = each.value.id
}

### GWLB ENDPOINTS ###

module "gwlbe_endpoint" {
  source = "../../modules/gwlb_endpoint_set"

  for_each = var.gwlb_endpoints

  name              = "${var.name_prefix}${each.value.name}"
  gwlb_service_name = module.gwlb[each.value.gwlb].endpoint_service.service_name
  vpc_id            = module.vpc[each.value.vpc].id
  subnets           = { for k, v in module.vpc[each.value.vpc].subnets : v.az => v if v.subnet_group == each.value.subnet_group }

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

### GWLB ASSOCIATIONS WITH VM-Series ENDPOINTS ###

locals {
  subinterface_gwlb_endpoint_eastwest = { for i, j in var.vmseries : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.eastwest : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_outbound = { for i, j in var.vmseries : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.outbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_inbound = { for i, j in var.vmseries : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.inbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  plugin_op_commands_with_endpoints_mapping = { for i, j in var.vmseries : i => format("%s,%s,%s,%s", j.bootstrap_options["plugin-op-commands"],
  local.subinterface_gwlb_endpoint_eastwest[i], local.subinterface_gwlb_endpoint_outbound[i], local.subinterface_gwlb_endpoint_inbound[i]) }
  bootstrap_options_with_endpoints_mapping = { for i, j in var.vmseries : i => [
    for k, v in j.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping[i]}"
  ] }
}

### VM-Series INSTANCES

locals {
  vmseries_instances = flatten([for kv, vv in var.vmseries : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, common = vv }]])
}

module "vmseries" {
  source = "../../modules/vmseries"

  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }

  name             = "${var.name_prefix}${each.key}"
  vmseries_version = each.value.common.panos_version

  interfaces = {
    for k, v in each.value.common.interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.vpc[each.value.common.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = module.vpc[v.vpc].subnets["${v.subnet_group}${each.value.az}"].id
      create_public_ip   = try(v.create_public_ip, false)
    }
  }

  bootstrap_options = join(";", compact(concat(local.bootstrap_options_with_endpoints_mapping[each.value.group])))

  iam_instance_profile = module.iam["vmseries"].instance_profile.name

  ssh_key_name = var.ssh_key_name
  tags         = var.tags
}

### Public ALB and NLB used in centralized model ###

module "public_alb" {
  source = "../../modules/alb"

  for_each = { for k, v in var.vmseries : k => v }

  lb_name         = "${var.name_prefix}${each.value.application_lb.name}"
  subnets         = { for k, v in module.vpc[each.value.vpc].subnets : k => { id = v.id } if v.subnet_group == each.value.application_lb.subnet_group }
  vpc_id          = module.vpc[each.value.vpc].id
  security_groups = [module.vpc[each.value.vpc].security_group_ids[each.value.application_lb.security_group]]
  rules           = each.value.application_lb.rules
  targets         = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => module.vmseries["${vmseries.group}-${vmseries.instance}"].interfaces["public"].private_ip }

  tags = var.tags
}

module "public_nlb" {
  source = "../../modules/nlb"

  for_each = { for k, v in var.vmseries : k => v }

  name        = "${var.name_prefix}${each.value.network_lb.name}"
  internal_lb = false
  subnets     = { for k, v in module.vpc[each.value.vpc].subnets : k => { id = v.id } if v.subnet_group == each.value.network_lb.subnet_group }
  vpc_id      = module.vpc[each.value.vpc].id

  balance_rules = { for k, v in each.value.network_lb.rules : k => {
    protocol           = v.protocol
    port               = v.port
    target_type        = v.target_type
    stickiness         = v.stickiness
    preserve_client_ip = v.preserve_client_ip
    targets            = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => module.vmseries["${vmseries.group}-${vmseries.instance}"].interfaces["public"].private_ip }
  } }

  tags = var.tags
}

### IAM ###

module "iam" {
  source = "../../modules/iam"

  for_each = var.iam_policies

  name_prefix             = var.name_prefix
  tags                    = var.tags
  role_name               = each.value.role_name
  create_instance_profile = try(each.value.create_instance_profile, false)
  instance_profile_name   = try(each.value.instance_profile_name, null)
  policy_arn              = try(each.value.policy_arn, null)
  create_vmseries_policy  = try(each.value.create_vmseries_policy, false)
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

resource "aws_instance" "spoke_vms" {
  for_each = var.spoke_vms

  ami                    = data.aws_ami.this.id
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  subnet_id              = module.vpc[each.value.vpc].subnets["${each.value.subnet_group}${each.value.az}"].id
  vpc_security_group_ids = [module.vpc[each.value.vpc].security_group_ids[each.value.security_group]]
  tags                   = merge({ Name = "${var.name_prefix}${each.key}" }, var.tags)
  iam_instance_profile   = module.iam["spoke"].instance_profile.name

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

### SPOKE INBOUND NETWORK LOAD BALANCER ###

module "app_lb" {
  source = "../../modules/nlb"

  for_each = var.spoke_lbs

  name        = "${var.name_prefix}${each.key}"
  internal_lb = true
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
    "HTTP-traffic" = {
      protocol    = "TCP"
      port        = "80"
      target_type = "instance"
      stickiness  = false
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
    "HTTPS-traffic" = {
      protocol    = "TCP"
      port        = "443"
      target_type = "instance"
      stickiness  = false
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
  }

  tags = var.tags
}
