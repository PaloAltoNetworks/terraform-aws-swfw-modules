module "vpc" {
  source = "../../modules/vpc"

  for_each = var.vpcs

  name                    = "${var.name_prefix}${each.value.name}"
  cidr_block              = each.value.cidr
  nacls                   = each.value.nacls
  security_groups         = each.value.security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

module "subnet_sets" {
  for_each = toset(flatten([for _, v in { for vk, vv in var.vpcs : vk => distinct([for sk, sv in vv.subnets : "${vk}-${sv.set}"]) } : v]))
  source   = "../../modules/subnet_set"

  name                = split("-", each.key)[1]
  vpc_id              = module.vpc[split("-", each.key)[0]].id
  has_secondary_cidrs = module.vpc[split("-", each.key)[0]].has_secondary_cidrs
  nacl_associations = {
    for i in flatten([
      for vk, vv in var.vpcs : [
        for sk, sv in vv.subnets :
        {
          az : sv.az,
          nacl_id : lookup(module.vpc[split("-", each.key)[0]].nacl_ids, sv.nacl, null)
        } if sv.nacl != null && each.key == "${vk}-${sv.set}"
    ]]) : i.az => i.nacl_id
  }
  cidrs = {
    for i in flatten([
      for vk, vv in var.vpcs : [
        for sk, sv in vv.subnets :
        {
          cidr : sk,
          subnet : sv
        } if each.key == "${vk}-${sv.set}"
    ]]) : i.cidr => i.subnet
  }
}

### NATGW ###

module "natgw_set" {
  source = "../../modules/nat_gateway_set"

  for_each = var.natgws

  subnets = module.subnet_sets[each.value.vpc_subnet].subnets
}

### ROUTES ###

locals {
  vpc_routes = flatten(concat([
    for vk, vv in var.vpcs : [
      for rk, rv in vv.routes : {
        subnet_key = rv.vpc_subnet
        to_cidr    = rv.to_cidr
        next_hop_set = (
          rv.next_hop_type == "internet_gateway" ? module.vpc[rv.next_hop_key].igw_as_next_hop_set : (
            rv.next_hop_type == "nat_gateway" ? module.natgw_set[rv.next_hop_key].next_hop_set : (
              rv.next_hop_type == "gwlbe_endpoint" ? module.gwlbe_endpoint[rv.next_hop_key].next_hop_set : null
            )
          )
        )
      }
    ]
  ]))
}

module "vpc_routes" {
  for_each = { for route in local.vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids = module.subnet_sets[each.value.subnet_key].unique_route_table_ids
  to_cidr         = each.value.to_cidr
  next_hop_set    = each.value.next_hop_set
}


### SPOKE INBOUND APPLICATION LOAD BALANCER ###

module "public_alb" {
  source   = "../../modules/alb"
  for_each = var.spoke_albs

  lb_name         = "${var.name_prefix}${each.key}"
  subnets         = { for k, v in module.subnet_sets[each.value.vpc_subnet].subnets : k => { id = v.id } }
  vpc_id          = module.vpc[each.value.vpc].id
  security_groups = [module.vpc[each.value.vpc].security_group_ids[each.value.security_groups]]
  rules           = each.value.rules
  targets         = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].private_ip }

  tags = var.global_tags
}

### SPOKE INBOUND NETWORK LOAD BALANCER ###

module "public_nlb" {
  source   = "../../modules/nlb"
  for_each = var.spoke_nlbs

  name        = "${var.name_prefix}${each.key}"
  internal_lb = false
  subnets     = { for k, v in module.subnet_sets[each.value.vpc_subnet].subnets : k => { id = v.id } }
  vpc_id      = module.subnet_sets[each.value.vpc_subnet].vpc_id

  balance_rules = {
    "SSH-traffic" = {
      protocol    = "TCP"
      port        = "22"
      target_type = "instance"
      stickiness  = true
      targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
    }
  }

  tags = var.global_tags
}

### CloudNGFW ###

module "cloudngfw" {
  source = "../../modules/cloudngfw"

  for_each = var.cloudngfws

  name           = "${var.name_prefix}${each.value.name}"
  subnets        = module.subnet_sets[each.value.vpc_subnet].subnets
  vpc_id         = module.vpc[each.value.vpc].id
  rulestack_name = "${var.name_prefix}${each.value.name}"
  description    = each.value.description
  security_rules = each.value.security_rules
  log_profiles   = each.value.log_profiles
}

### GWLB ENDPOINTS ###

module "gwlbe_endpoint" {
  source = "../../modules/gwlb_endpoint_set"

  for_each = var.gwlb_endpoints

  name              = "${var.name_prefix}${each.value.name}"
  gwlb_service_name = module.cloudngfw[each.value.cloudngfw].cloudngfw_service_name
  vpc_id            = module.subnet_sets[each.value.vpc_subnet].vpc_id
  subnets           = module.subnet_sets[each.value.vpc_subnet].subnets
  delay             = each.value.delay

  act_as_next_hop_for = each.value.act_as_next_hop ? {
    "from-igw-to-lb" = {
      route_table_id = module.vpc[each.value.vpc].internet_gateway_route_table.id
      to_subnets     = module.subnet_sets[each.value.to_vpc_subnets].subnets
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
    name   = "name"
    values = ["bitnami-nginx-1.25*-linux-debian-11-x86_64-hvm-ebs-nami"]
    # The wildcard '*' causes re-creation of the whole EC2 instance when a new image appears.
  }

  owners = ["979382823631"] # bitnami = 979382823631
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

resource "aws_iam_instance_profile" "spoke_vm_iam_instance_profile" {

  name = "${var.name_prefix}spoke_vm_instance_profile"
  role = aws_iam_role.spoke_vm_ec2_iam_role.name
}

resource "aws_instance" "spoke_vms" {
  for_each = var.spoke_vms

  ami                    = data.aws_ami.this.id
  instance_type          = each.value.type
  key_name               = var.ssh_key_name
  subnet_id              = module.subnet_sets[each.value.vpc_subnet].subnets[each.value.az].id
  vpc_security_group_ids = [module.vpc[each.value.vpc].security_group_ids[each.value.security_group]]
  tags                   = merge({ Name = "${var.name_prefix}${each.key}" }, var.global_tags)
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
}