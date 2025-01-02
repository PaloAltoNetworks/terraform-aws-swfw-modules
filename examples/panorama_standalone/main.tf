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

  internet_gateway_id = each.value.next_hop_type == "internet_gateway" ? module.vpc[each.value.next_hop_key].internet_gateway.id : null
}

### IAM ###

module "iam" {
  source = "../../modules/iam"

  for_each = var.iam_policies

  name_prefix              = var.name_prefix
  tags                     = var.tags
  role_name                = each.value.role_name
  create_role              = each.value.create_role
  principal_role           = each.value.principal_role
  create_instance_profile  = each.value.create_instance_profile
  instance_profile_name    = each.value.instance_profile_name
  create_lambda_policy     = each.value.create_lambda_policy
  create_bootrap_policy    = each.value.create_bootrap_policy
  policy_arn               = each.value.policy_arn
  create_vmseries_policy   = each.value.create_vmseries_policy
  create_panorama_policy   = each.value.create_panorama_policy
  custom_policy            = each.value.custom_policy
  delicense_ssm_param_name = each.value.delicense_ssm_param_name
  aws_s3_bucket            = each.value.aws_s3_bucket
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
  availability_zone      = "${var.region}${each.value.az}"
  create_public_ip       = each.value.common.network.create_public_ip
  private_ip_address     = each.value.private_ip_address
  ebs_volumes            = each.value.common.ebs.volumes
  ebs_encrypted          = each.value.common.ebs.encrypted
  panorama_version       = each.value.common.panos_version
  ssh_key_name           = var.ssh_key_name
  ebs_kms_key_alias      = each.value.common.ebs.kms_key_alias
  subnet_id              = module.vpc[each.value.common.network.vpc].subnets["${each.value.common.network.subnet_group}${each.value.az}"].id
  vpc_security_group_ids = [module.vpc[each.value.common.network.vpc].security_group_ids[each.value.common.network.security_group]]
  panorama_iam_role      = module.iam["panorama"].instance_profile.name
  enable_imdsv2          = each.value.common.enable_imdsv2

  global_tags = var.tags
}
