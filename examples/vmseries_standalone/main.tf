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

  route_table_id   = module.vpc[each.value.vpc].route_tables[each.value.route_table].id
  to_cidr          = each.value.to_cidr
  destination_type = each.value.destination_type
  next_hop_type    = each.value.next_hop_type

  internet_gateway_id = each.value.next_hop_type == "internet_gateway" ? module.vpc[each.value.next_hop_key].internet_gateway.id : null
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
  create_vmseries_policy  = try(each.value.create_vmseries_policy, false)
  create_bootrap_policy   = try(each.value.create_bootrap_policy, false)
  aws_s3_bucket           = try(each.value.aws_s3_bucket, null)
}

### BOOTSTRAP PACKAGE
module "bootstrap" {
  source = "../../modules/bootstrap"

  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }

  prefix = var.name_prefix

  bootstrap_options     = merge(each.value.common.bootstrap_options, { hostname = "${var.name_prefix}${each.key}" })
  source_root_directory = "files"
  bucket_name           = try(each.value.common.bucket_name, null)
}

### VM-Series INSTANCES

locals {
  vmseries_instances = flatten([for kv, vv in var.vmseries : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, common = vv }]])
}

module "vmseries" {
  source = "../../modules/vmseries"

  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }

  name              = "${var.name_prefix}${each.key}"
  vmseries_version  = each.value.common.panos_version
  ebs_kms_key_alias = each.value.common.ebs_kms_id

  interfaces = {
    for k, v in each.value.common.interfaces : k => {
      device_index       = v.device_index
      private_ips        = [v.private_ip[each.value.instance]]
      security_group_ids = try([module.vpc[each.value.common.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = module.vpc[v.vpc].subnets["${v.subnet_group}${each.value.az}"].id
      create_public_ip   = try(v.create_public_ip, false)
      eip_allocation_id  = try(v.eip_allocation_id[each.value.instance], null)
      ipv6_address_count = try(v.ipv6_address_count, null)
    }
  }

  bootstrap_options = join(";", compact(concat(
    ["vmseries-bootstrap-aws-s3bucket=${module.bootstrap[each.key].bucket_name}"],
    ["mgmt-interface-swap=${each.value.common.bootstrap_options["mgmt-interface-swap"]}"],
  )))

  iam_instance_profile = module.iam["vmseries"].instance_profile.name
  ssh_key_name         = var.ssh_key_name
  tags                 = var.tags
}
