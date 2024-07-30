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
  #      subnet        = "tgw_attach"
  #      to_cidr       = "0.0.0.0/0"
  #      next_hop_key  = "security_gwlb_outbound"
  #      next_hop_type = "gwlbe_endpoint"
  #    }
  #
  # Value of `next_hop_type` defines the type of the next hop. It can be one of the following:
  # - internet_gateway
  #
  # Please note, that in this example only internet_gateway is allowed, because no NAT Gateway, TGW or GWLB endpoints are created in main.tf
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
          "internet_gateway" = try(module.vpc[rv.next_hop_key].igw_as_next_hop_set, null)
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

### IAM ROLES AND POLICIES ###

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

resource "aws_iam_role" "this" {
  for_each           = var.panoramas
  name               = "${var.name_prefix}${each.value.iam.role_name}"
  description        = "Allow read-only access to AWS resources."
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
  tags               = var.tags
}

resource "aws_iam_role_policy" "this" {
  for_each = var.panoramas
  role     = aws_iam_role.this[each.key].id
  policy   = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "ec2:DescribeInstanceStatus",
              "ec2:DescribeInstances"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "cloudwatch:ListMetrics",
                "cloudwatch:GetMetricStatistics",
                "cloudwatch:DescribeAlarmsForMetric"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
              "cloudwatch:DescribeAlarms"
            ],
            "Resource": [
              "arn:${data.aws_partition.this.partition}:cloudwatch:${var.region}:${data.aws_caller_identity.this.account_id}:alarm:*"
            ]
        }
    ]
}

EOF
}

resource "aws_iam_instance_profile" "this" {
  for_each = { for panorama in local.panorama_instances : "${panorama.group}-${panorama.instance}" => panorama }
  name     = "${var.name_prefix}${each.key}panorama_instance_profile"
  role     = each.value.common.iam.create_role ? aws_iam_role.this[each.value.group].name : each.value.common.iam.role_name
}

### PANORAMA INSTANCES

locals {
  panorama_instances = flatten([for kv, vv in var.panoramas : [for ki, vi in vv.instances : {
    group              = kv
    instance           = ki
    az                 = vi.az
    private_ip_address = vi.private_ip_address
    common             = vv
  }]])
}

module "panorama" {
  source = "../../modules/panorama"

  for_each = { for panorama in local.panorama_instances : "${panorama.group}-${panorama.instance}" => panorama }

  name                   = "${var.name_prefix}${each.key}"
  availability_zone      = each.value.az
  create_public_ip       = each.value.common.network.create_public_ip
  private_ip_address     = each.value.private_ip_address
  ebs_volumes            = each.value.common.ebs.volumes
  ebs_encrypted          = each.value.common.ebs.encrypted
  panorama_version       = each.value.common.panos_version
  ssh_key_name           = var.ssh_key_name
  ebs_kms_key_alias      = each.value.common.ebs.kms_key_alias
  subnet_id              = module.vpc[each.value.common.network.vpc].subnets["${each.value.common.network.subnet_group}${each.value.az}"].id
  vpc_security_group_ids = [module.vpc[each.value.common.network.vpc].security_group_ids[each.value.common.network.security_group]]
  panorama_iam_role      = aws_iam_instance_profile.this[each.key].name
  enable_imdsv2          = each.value.common.enable_imdsv2

  global_tags = var.tags

  depends_on = [
    aws_iam_instance_profile.this
  ]
}
