### VPCS ###

module "vpc" {
  source = "../../modules/vpc"

  for_each = var.vpcs

  name                             = "${var.name_prefix}${each.value.name}"
  cidr_block                       = each.value.cidr
  assign_generated_ipv6_cidr_block = each.value.assign_generated_ipv6_cidr_block
  nacls                            = each.value.nacls
  security_groups                  = each.value.security_groups
  create_internet_gateway          = true
  enable_dns_hostnames             = true
  enable_dns_support               = true
  instance_tenancy                 = "default"
}

### SUBNETS ###

resource "aws_subnet" "subnets" {
  for_each          = local.merged_subnets
  vpc_id            = module.vpc[split("-", each.key)[0]].id
  cidr_block        = each.value.cidr
  ipv6_cidr_block   = try(cidrsubnet(module.vpc[split("-", each.key)[0]].vpc.ipv6_cidr_block, 8, each.value.ipv6_index), null)
  availability_zone = each.value.az
  tags = {
    Name = "${var.name_prefix}${split("-", each.key)[1]}"
  }
}

resource "aws_route_table" "route_tables" {
  for_each = local.merged_subnets
  vpc_id   = module.vpc[split("-", each.key)[0]].id
  tags = {
    Name = "${var.name_prefix}${split("-", each.key)[1]}"
  }
}

resource "aws_route_table_association" "rt_associate" {
  for_each       = local.merged_subnets
  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = aws_route_table.route_tables[each.key].id
}

### ROUTES ###

locals {
  vpc_routes = flatten(concat([
    for vk, vv in var.vpcs : [
      for rk, rv in vv.routes : {
        subnet_key       = rv.vpc_subnet
        to_cidr          = rv.to_cidr
        destination_type = rv.destination_type
        next_hop_set = (
          rv.next_hop_type == "internet_gateway" ? module.vpc[rv.next_hop_key].igw_as_next_hop_set : null
        )
      }
    ]
  ]))
  subnets = { for vk, vv in var.vpcs : vk => { for sk, sv in vv.subnets : "${vk}-${sv.set}" => merge(sv, { cidr = sk }) } }
  merged_subnets = merge([for vk, vv in local.subnets : { for sk, sv in vv : sk => {
    az         = sv.az
    ipv6_index = sv.ipv6_index
    nacl       = sv.nacl
    cidr       = sv.cidr
  set = sv.set } }]...)
}

module "vpc_routes" {
  for_each = { for route in local.vpc_routes : "${route.subnet_key}_${route.to_cidr}" => route }
  source   = "../../modules/vpc_route"

  route_table_ids  = { for k, v in aws_route_table.route_tables : k => v.id if k == each.value.subnet_key }
  to_cidr          = each.value.to_cidr
  destination_type = try(each.value.destination_type, null)
  next_hop_set     = each.value.next_hop_set
}

### IAM ROLES AND POLICIES ###

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

resource "aws_iam_role_policy" "this" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }
  role     = module.bootstrap[each.key].iam_role_name
  policy   = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricData",
        "cloudwatch:ListMetrics"
      ],
      "Resource": [
        "*"
      ],
      "Effect": "Allow"
    },
    {
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DescribeAlarms"
      ],
      "Resource": [
        "arn:${data.aws_partition.this.partition}:cloudwatch:${var.region}:${data.aws_caller_identity.this.account_id}:alarm:*"
      ],
      "Effect": "Allow"
    }
  ]
}

EOF
}

### BOOTSTRAP PACKAGE
module "bootstrap" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }
  source   = "../../modules/bootstrap"

  iam_role_name             = "${var.name_prefix}vmseries${each.value.instance}"
  iam_instance_profile_name = "${var.name_prefix}vmseries_instance_profile${each.value.instance}"

  prefix      = var.name_prefix
  global_tags = var.global_tags

  bootstrap_options     = merge(each.value.common.bootstrap_options, { hostname = "${var.name_prefix}${each.key}" })
  source_root_directory = "files-${each.key}/"
}

### VM-Series INSTANCES

locals {
  vmseries_instances = flatten([for kv, vv in var.vmseries : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, common = vv }]])
}

module "vmseries" {
  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }
  source   = "../../modules/vmseries"

  name             = "${var.name_prefix}${each.key}"
  vmseries_version = each.value.common.panos_version

  interfaces = {
    for k, v in each.value.common.interfaces : k => {
      device_index       = v.device_index
      private_ips        = [v.private_ip[each.value.instance]]
      security_group_ids = try([module.vpc[each.value.common.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = aws_subnet.subnets[v.vpc_subnet].id
      create_public_ip   = try(v.create_public_ip, false)
      eip_allocation_id  = try(v.eip_allocation_id[each.value.instance], null)
      ipv6_address_count = try(v.ipv6_address_count, null)
    }
  }

  bootstrap_options = join(";", compact(concat(
    ["vmseries-bootstrap-aws-s3bucket=${module.bootstrap[each.key].bucket_name}"],
    ["mgmt-interface-swap=${each.value.common.bootstrap_options["mgmt-interface-swap"]}"],
  )))

  iam_instance_profile = module.bootstrap[each.key].instance_profile_name
  ssh_key_name         = var.ssh_key_name
  tags                 = var.global_tags
}
