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

  internet_gateway_id       = each.value.next_hop_type == "internet_gateway" ? module.vpc[each.value.next_hop_key].internet_gateway.id : null
  vpc_peering_connection_id = each.value.next_hop_type == "vpc_peer" ? aws_vpc_peering_connection.this[0].id : null
  vpc_endpoint_id           = each.value.next_hop_type == "gwlbe_endpoint" ? module.gwlbe_endpoint[each.value.next_hop_key].next_hop_set.ids[each.value.az] : null
}

### VPC PEERINGS ###

resource "aws_vpc_peering_connection" "this" {
  count       = var.panorama_connection.peering_vpc_id != null ? 1 : 0
  peer_vpc_id = var.panorama_connection.peering_vpc_id
  vpc_id      = module.vpc[var.panorama_connection.security_vpc].id
  auto_accept = true

  tags = {
    Name = "${var.name_prefix}panorama-security-vpc-peering"
  }
}

### GWLB ###

module "gwlb" {
  source = "../../modules/gwlb"

  for_each = var.gwlbs

  name    = "${var.name_prefix}${each.value.name}"
  vpc_id  = module.vpc[each.value.vpc].id
  subnets = { for k, v in module.vpc[each.value.vpc].subnets : v.az => v if v.subnet_group == each.value.subnet_group }
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
  subinterface_gwlb_endpoint_eastwest = { for i, j in var.vmseries_asgs : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.eastwest : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_outbound = { for i, j in var.vmseries_asgs : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.outbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  subinterface_gwlb_endpoint_inbound = { for i, j in var.vmseries_asgs : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.inbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }
  plugin_op_commands_with_endpoints_mapping = { for i, j in var.vmseries_asgs : i => format("%s,%s,%s,%s", j.bootstrap_options["plugin-op-commands"],
  local.subinterface_gwlb_endpoint_eastwest[i], local.subinterface_gwlb_endpoint_outbound[i], local.subinterface_gwlb_endpoint_inbound[i]) }
  bootstrap_options_with_endpoints_mapping = { for i, j in var.vmseries_asgs : i => [
    for k, v in j.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping[i]}"
  ] }
}

### IAM ROLES AND POLICIES ###

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

resource "aws_iam_role" "vm_series_ec2_iam_role" {
  name               = "${var.name_prefix}vmseries"
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

resource "aws_iam_role_policy" "vm_series_ec2_iam_policy" {
  role   = aws_iam_role.vm_series_ec2_iam_role.id
  policy = <<EOF
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

resource "aws_iam_instance_profile" "vm_series_iam_instance_profile" {

  name = "${var.name_prefix}vmseries_instance_profile"
  role = aws_iam_role.vm_series_ec2_iam_role.name
}

### AUTOSCALING GROUP WITH VM-Series INSTANCES ###

module "vm_series_asg" {
  source = "../../modules/asg"

  for_each = var.vmseries_asgs

  ssh_key_name                    = var.ssh_key_name
  region                          = var.region
  name_prefix                     = var.name_prefix
  global_tags                     = var.tags
  vmseries_version                = each.value.panos_version
  max_size                        = each.value.asg.max_size
  min_size                        = each.value.asg.min_size
  desired_capacity                = each.value.asg.desired_cap
  lambda_execute_pip_install_once = each.value.asg.lambda_execute_pip_install_once
  instance_refresh                = each.value.instance_refresh
  launch_template_version         = each.value.launch_template_version
  vmseries_iam_instance_profile   = aws_iam_instance_profile.vm_series_iam_instance_profile.name
  subnet_ids                      = [for i, j in var.vpcs[each.value.vpc].subnets : module.vpc[each.value.vpc].subnets["lambda${j.az}"].id if j.subnet_group == "lambda"]
  security_group_ids              = contains(keys(module.vpc[each.value.vpc].security_group_ids), "lambda") ? [module.vpc[each.value.vpc].security_group_ids["lambda"]] : []
  interfaces = {
    for k, v in each.value.interfaces : k => {
      device_index       = v.device_index
      security_group_ids = try([module.vpc[each.value.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = try(v.source_dest_check, false)
      subnet_id          = { for z, c in each.value.zones : c => module.vpc[each.value.vpc].subnets["${v.subnet_group}${c}"].id }
      create_public_ip   = try(v.create_public_ip, false)
    }
  }
  ebs_kms_id        = each.value.ebs_kms_id
  target_group_arn  = module.gwlb[each.value.gwlb].target_group.arn
  bootstrap_options = join(";", compact(concat(local.bootstrap_options_with_endpoints_mapping[each.key])))

  scaling_plan_enabled              = each.value.scaling_plan.enabled
  scaling_metric_name               = each.value.scaling_plan.metric_name
  scaling_estimated_instance_warmup = each.value.scaling_plan.estimated_instance_warmup
  scaling_target_value              = each.value.scaling_plan.target_value
  scaling_statistic                 = each.value.scaling_plan.statistic
  scaling_cloudwatch_namespace      = each.value.scaling_plan.cloudwatch_namespace
  scaling_tags                      = merge(each.value.scaling_plan.tags, { prefix : var.name_prefix })
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