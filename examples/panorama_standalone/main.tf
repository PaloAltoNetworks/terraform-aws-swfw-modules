### VPCS ###

module "vpc" {
  source = "../../modules/vpc"

  for_each = var.vpcs

  name                    = "${var.name_prefix}${each.value.name}"
  cidr_block              = each.value.cidr
  security_groups         = each.value.security_groups
  create_internet_gateway = true
  enable_dns_hostnames    = true
  enable_dns_support      = true
  instance_tenancy        = "default"
}

### SUBNETS ###

locals {
  # Flatten the VPCs and their subnets into a list of maps, each containing the VPC name, subnet name, and subnet details.
  subnets_in_vpcs = flatten([for vk, vv in var.vpcs : [for sk, sv in vv.subnets :
    {
      cidr                    = sk
      nacl                    = sv.nacl
      az                      = sv.az
      subnet                  = sv.set
      vpc                     = vk
      create_subnet           = try(sv.create_subnet, true)
      create_route_table      = try(sv.create_route_table, sv.create_subnet, true)
      existing_route_table_id = try(sv.existing_route_table_id, null)
      associate_route_table   = try(sv.associate_route_table, true)
      route_table_name        = try(sv.route_table_name, null)
      local_tags              = try(sv.local_tags, {})
    }
  ]])
  # Create a map of subnets, keyed by the VPC name and subnet name.
  subnets_with_lists = { for subnet_in_vpc in local.subnets_in_vpcs : "${subnet_in_vpc.vpc}-${subnet_in_vpc.subnet}" => subnet_in_vpc... }
  subnets = { for key, value in local.subnets_with_lists : key => {
    vpc                     = distinct([for v in value : v.vpc])[0]                               # VPC name (always take first from the list as key is limitting number of VPCs)
    subnet                  = distinct([for v in value : v.subnet])[0]                            # Subnet name (always take first from the list as key is limitting number of subnets)
    az                      = [for v in value : v.az]                                             # List of AZs
    cidr                    = [for v in value : v.cidr]                                           # List of CIDRs
    nacl                    = compact([for v in value : v.nacl])                                  # List of NACLs
    create_subnet           = [for v in value : try(v.create_subnet, true)]                       # List of create_subnet flags
    create_route_table      = [for v in value : try(v.create_route_table, v.create_subnet, true)] # List of create_route_table flags
    existing_route_table_id = [for v in value : try(v.existing_route_table_id, null)]             # List of existing_route_table_id values
    associate_route_table   = [for v in value : try(v.associate_route_table, true)]               # List of associate_route_table flags
    route_table_name        = [for v in value : try(v.route_table_name, null)]                    # List of route_table_name values
    local_tags              = [for v in value : try(v.local_tags, {})]                            # List of local_tags maps
  } }
}

module "subnet_sets" {
  source = "../../modules/subnet_set"

  for_each = local.subnets

  name                = each.value.subnet
  vpc_id              = module.vpc[each.value.vpc].id
  has_secondary_cidrs = module.vpc[each.value.vpc].has_secondary_cidrs
  nacl_associations = {
    for index, az in each.value.az : az =>
    lookup(module.vpc[each.value.vpc].nacl_ids, each.value.nacl[index], null) if length(each.value.nacl) > 0
  }
  cidrs = {
    for index, cidr in each.value.cidr : cidr => {
      az                      = each.value.az[index]
      create_subnet           = each.value.create_subnet[index]
      create_route_table      = each.value.create_route_table[index]
      existing_route_table_id = each.value.existing_route_table_id[index]
      associate_route_table   = each.value.associate_route_table[index]
      route_table_name        = each.value.route_table_name[index]
      local_tags              = each.value.local_tags[index]
  } }
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
        subnet        = rv.subnet
        to_cidr       = rv.to_cidr
        next_hop_type = rv.next_hop_type
        next_hop_map = {
          "internet_gateway" = try(module.vpc[rv.next_hop_key].igw_as_next_hop_set, null)
        }
      }
  ]]))
  vpc_routes = {
    for route in local.vpc_routes_with_next_hop_map : "${route.vpc}-${route.subnet}-${route.to_cidr}" => {
      vpc          = route.vpc
      subnet       = route.subnet
      to_cidr      = route.to_cidr
      next_hop_set = lookup(route.next_hop_map, route.next_hop_type, null)
    }
  }
}

module "vpc_routes" {
  source = "../../modules/vpc_route"

  for_each = local.vpc_routes

  route_table_ids = module.subnet_sets["${each.value.vpc}-${each.value.subnet}"].unique_route_table_ids
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
  tags               = var.global_tags
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
  subnet_id              = module.subnet_sets["${each.value.common.network.vpc}-${each.value.common.network.subnet}"].subnets[each.value.az].id
  vpc_security_group_ids = [module.vpc[each.value.common.network.vpc].security_group_ids[each.value.common.network.security_group]]
  panorama_iam_role      = aws_iam_instance_profile.this[each.key].name
  enable_imdsv2          = each.value.common.enable_imdsv2

  global_tags = var.global_tags

  depends_on = [
    aws_iam_instance_profile.this
  ]
}
