### VPCS ###

module "vpc" {
  source = "../../modules/vpc"

  for_each = var.vpcs

  name                             = each.value.create_vpc ? "${var.name_prefix}${each.value.name}" : each.value.name
  create_vpc                       = each.value.create_vpc
  cidr_block                       = each.value.cidr
  secondary_cidr_blocks            = each.value.secondary_cidr_blocks
  assign_generated_ipv6_cidr_block = each.value.assign_generated_ipv6_cidr_block
  use_internet_gateway             = each.value.use_internet_gateway
  nacls                            = each.value.nacls
  security_groups                  = each.value.security_groups
  name_internet_gateway            = each.value.name_internet_gateway
  route_table_internet_gateway     = each.value.route_table_internet_gateway
  create_internet_gateway          = each.value.create_internet_gateway
  create_vpn_gateway               = each.value.create_vpn_gateway
  vpn_gateway_amazon_side_asn      = each.value.vpn_gateway_amazon_side_asn
  name_vpn_gateway                 = each.value.name_vpn_gateway
  enable_dns_hostnames             = each.value.enable_dns_hostnames
  enable_dns_support               = each.value.enable_dns_support
  instance_tenancy                 = each.value.instance_tenancy
  create_dhcp_options              = each.value.create_dhcp_options
  domain_name                      = each.value.domain_name
  domain_name_servers              = each.value.domain_name_servers
  ntp_servers                      = each.value.ntp_servers
  vpc_tags                         = each.value.vpc_tags
  global_tags                      = var.global_tags
}

### SUBNETS ###

locals {
  # Flatten the VPCs and their subnets into a list of maps, each containing the VPC name, subnet name, and subnet details.
  subnets_in_vpcs = flatten([for vk, vv in var.vpcs : [for sk, sv in vv.subnets :
    {
      name                    = sv.name
      cidr                    = sk
      nacl                    = sv.nacl
      az                      = sv.az
      subnet                  = sv.subnet_group
      vpc                     = vk
      create_subnet           = sv.create_subnet
      create_route_table      = sv.create_route_table
      existing_route_table_id = sv.existing_route_table_id
      associate_route_table   = sv.associate_route_table
      route_table_name        = sv.route_table_name
      local_tags              = sv.local_tags
      map_public_ip_on_launch = sv.map_public_ip_on_launch
    }
  ]])
  # Create a map of subnets, keyed by the VPC name and subnet name.
  subnets_with_lists = { for subnet_in_vpc in local.subnets_in_vpcs : "${subnet_in_vpc.vpc}-${subnet_in_vpc.subnet}" => subnet_in_vpc... }
  subnets = { for key, value in local.subnets_with_lists : key => {
    vpc                     = distinct([for v in value : v.vpc])[0]    # VPC name (always take first from the list as key is limitting number of VPCs)
    subnet                  = distinct([for v in value : v.subnet])[0] # Subnet name (always take first from the list as key is limitting number of subnets)
    name                    = [for v in value : v.name]
    az                      = [for v in value : v.az]                                             # List of AZs
    cidr                    = [for v in value : v.cidr]                                           # List of CIDRs
    nacl                    = compact([for v in value : v.nacl])                                  # List of NACLs
    create_subnet           = [for v in value : try(v.create_subnet, true)]                       # List of create_subnet flags
    create_route_table      = [for v in value : try(v.create_route_table, v.create_subnet, true)] # List of create_route_table flags
    existing_route_table_id = [for v in value : try(v.existing_route_table_id, null)]             # List of existing_route_table_id values
    associate_route_table   = [for v in value : try(v.associate_route_table, true)]               # List of associate_route_table flags
    route_table_name        = [for v in value : try(v.route_table_name, null)]                    # List of route_table_name values
    local_tags              = [for v in value : try(v.local_tags, {})]                            # List of local_tags maps
    map_public_ip_on_launch = [for v in value : try(v.map_public_ip_on_launch, {})]               # List of map_public_ip_on_launch flags
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
      name                    = each.value.name[index]
      az                      = each.value.az[index]
      create_subnet           = each.value.create_subnet[index]
      create_route_table      = each.value.create_route_table[index]
      existing_route_table_id = each.value.existing_route_table_id[index]
      associate_route_table   = each.value.associate_route_table[index]
      route_table_name        = each.value.route_table_name[index]
      local_tags              = each.value.local_tags[index]
      map_public_ip_on_launch = each.value.map_public_ip_on_launch[index]
  } }
  global_tags = var.global_tags
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
        subnet        = rv.subnet_group
        to_cidr       = rv.to_cidr
        next_hop_type = rv.next_hop_type
        next_hop_map = {
          "internet_gateway" = try(module.vpc[rv.next_hop_key].igw_as_next_hop_set, null)
          "nat_gateway"      = try(module.natgw_set[rv.next_hop_key].next_hop_set, null)
          "gwlbe_endpoint"   = try(module.gwlbe_endpoint[rv.next_hop_key].next_hop_set, null)
        }
        destination_type       = rv.destination_type
        managed_prefix_list_id = rv.managed_prefix_list_id
      } if(rv.next_hop_type == "gwlbe_endpoint" && length(var.gwlb_endpoints) > 0) ||
      (rv.next_hop_type == "nat_gateway" && length(var.natgws) > 0) ||
      rv.next_hop_type == "internet_gateway"
  ]]))
  vpc_routes = {
    for route in local.vpc_routes_with_next_hop_map : "${route.vpc}-${route.subnet}-${route.to_cidr}" => {
      vpc                    = route.vpc
      subnet                 = route.subnet
      to_cidr                = route.to_cidr
      next_hop_set           = lookup(route.next_hop_map, route.next_hop_type, null)
      destination_type       = route.destination_type
      managed_prefix_list_id = route.managed_prefix_list_id
    }
  }
}

module "vpc_routes" {
  source = "../../modules/vpc_route"

  for_each = local.vpc_routes

  route_table_ids        = module.subnet_sets["${each.value.vpc}-${each.value.subnet}"].unique_route_table_ids
  to_cidr                = each.value.to_cidr
  next_hop_set           = each.value.next_hop_set
  destination_type       = each.value.destination_type
  managed_prefix_list_id = each.value.managed_prefix_list_id
}

### NATGW ###

module "natgw_set" {
  source = "../../modules/nat_gateway_set"

  for_each = var.natgws

  create_nat_gateway = each.value.create_nat_gateway
  nat_gateway_names  = each.value.nat_gateway_names
  subnets            = module.subnet_sets["${each.value.vpc}-${each.value.subnet_group}"].subnets
  nat_gateway_tags   = each.value.nat_gateway_tags
  create_eip         = each.value.create_eip
  eips               = each.value.eips
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

  name                          = "${var.name_prefix}${each.value.name}"
  vpc_id                        = module.subnet_sets["${each.value.vpc}-${each.value.subnet_group}"].vpc_id
  subnets                       = module.subnet_sets["${each.value.vpc}-${each.value.subnet_group}"].subnets
  tg_name                       = each.value.tg_name
  target_instances              = each.value.target_instances
  acceptance_required           = each.value.acceptance_required
  allowed_principals            = each.value.allowed_principals
  deregistration_delay          = each.value.deregistration_delay
  health_check_enabled          = each.value.health_check_enabled
  health_check_interval         = each.value.health_check_interval
  health_check_matcher          = each.value.health_check_matcher
  health_check_path             = each.value.health_check_path
  health_check_port             = each.value.health_check_port
  health_check_protocol         = each.value.health_check_protocol
  health_check_timeout          = each.value.health_check_timeout
  healthy_threshold             = each.value.healthy_threshold
  unhealthy_threshold           = each.value.unhealthy_threshold
  stickiness_type               = each.value.stickiness_type
  rebalance_flows               = each.value.rebalance_flows
  lb_tags                       = each.value.lb_tags
  lb_target_group_tags          = each.value.lb_target_group_tags
  endpoint_service_tags         = each.value.endpoint_service_tags
  enable_lb_deletion_protection = each.value.enable_lb_deletion_protection
  global_tags                   = var.global_tags
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
  custom_names      = each.value.custom_names
  gwlb_service_name = module.gwlb[each.value.gwlb].endpoint_service.service_name
  vpc_id            = module.subnet_sets["${each.value.vpc}-${each.value.subnet_group}"].vpc_id
  subnets           = module.subnet_sets["${each.value.vpc}-${each.value.subnet_group}"].subnets

  act_as_next_hop_for = each.value.act_as_next_hop ? {
    "from-igw-to-lb" = {
      route_table_id = module.vpc[each.value.vpc].internet_gateway_route_table.id
      to_subnets     = module.subnet_sets["${each.value.from_igw_to_vpc}-${each.value.from_igw_to_subnet_group}"].subnets
    }
    # The routes in this section are special in that they are on the "edge", that is they are part of an IGW route table,
    # and AWS allows their destinations to only be:
    #     - The entire IPv4 or IPv6 CIDR block of your VPC. (Not interesting, as we always want AZ-specific next hops.)
    #     - The entire IPv4 or IPv6 CIDR block of a subnet in your VPC. (This is used here.)
    # Source: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html#gateway-route-table
  } : {}
  delay = each.value.delay
  tags  = merge(var.global_tags, each.value.tags)
}


### GWLB ASSOCIATIONS WITH VM-Series ENDPOINTS ###

locals {
  subinterface_gwlb_endpoint_eastwest = try({ for i, j in var.vmseries : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.eastwest : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }, {})
  subinterface_gwlb_endpoint_outbound = try({ for i, j in var.vmseries : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.outbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }, {})
  subinterface_gwlb_endpoint_inbound = try({ for i, j in var.vmseries : i => join(",", compact(concat(flatten([
    for sk, sv in j.subinterfaces.inbound : [for k, v in module.gwlbe_endpoint[sv.gwlb_endpoint].endpoints : format("aws-gwlb-associate-vpce:%s@%s", v.id, sv.subinterface)]
  ])))) }, {})
  plugin_op_commands_with_endpoints_mapping = { for i, j in var.vmseries : i => join(",", compact([j.bootstrap_options["plugin-op-commands"],
  try(local.subinterface_gwlb_endpoint_eastwest[i], null), try(local.subinterface_gwlb_endpoint_outbound[i], null), try(local.subinterface_gwlb_endpoint_inbound[i], null)])) }
  bootstrap_options_with_endpoints_mapping = { for i, j in var.vmseries : i => [
    for k, v in j.bootstrap_options : k != "plugin-op-commands" ? "${k}=${v}" : "${k}=${local.plugin_op_commands_with_endpoints_mapping[i]}" if v != null
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

### VM-Series INSTANCES

locals {
  vmseries_instances = flatten([for kv, vv in var.vmseries : [for ki, vi in vv.instances : { group = kv, instance = ki, az = vi.az, name = vi.name, common = vv }]])
}

module "vmseries" {
  source = "../../modules/vmseries"

  for_each = { for vmseries in local.vmseries_instances : "${vmseries.group}-${vmseries.instance}" => vmseries }

  name                                   = each.value.name != null ? "${var.name_prefix}${each.value.name}" : "${var.name_prefix}${each.key}"
  vmseries_version                       = each.value.common.panos_version
  vmseries_ami_id                        = each.value.common.vmseries_ami_id
  vmseries_product_code                  = each.value.common.vmseries_product_code
  include_deprecated_ami                 = each.value.common.include_deprecated_ami
  instance_type                          = each.value.common.instance_type
  enable_instance_termination_protection = each.value.common.enable_instance_termination_protection
  enable_monitoring                      = each.value.common.enable_monitoring
  ebs_encrypted                          = each.value.common.ebs_encrypted
  ebs_kms_key_alias                      = each.value.common.ebs_kms_id

  interfaces = {
    for k, v in each.value.common.interfaces : k => {
      device_index       = v.device_index
      name               = v.name
      description        = v.description
      security_group_ids = try([module.vpc[each.value.common.vpc].security_group_ids[v.security_group]], [])
      source_dest_check  = v.source_dest_check
      subnet_id          = module.subnet_sets["${each.value.common.vpc}-${v.subnet_group}"].subnets[each.value.az].id
      create_public_ip   = v.create_public_ip
      eip_allocation_id  = v.eip_allocation_id
      private_ips        = v.private_ips
      ipv6_address_count = v.ipv6_address_count
      public_ipv4_pool   = v.public_ipv4_pool
    }
  }

  bootstrap_options = join(";", compact(concat(local.bootstrap_options_with_endpoints_mapping[each.value.group])))

  iam_instance_profile = aws_iam_instance_profile.vm_series_iam_instance_profile.name
  ssh_key_name         = var.ssh_key_name
  tags                 = merge(var.global_tags, each.value.common.tags)
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

data "aws_kms_key" "current" {
  key_id = data.aws_ebs_default_kms_key.current.key_arn
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
  subnet_id              = module.subnet_sets["${each.value.vpc}-${each.value.subnet_group}"].subnets[each.value.az].id
  vpc_security_group_ids = [module.vpc[each.value.vpc].security_group_ids[each.value.security_group]]
  tags                   = merge({ Name = "${var.name_prefix}${each.key}" }, var.global_tags)
  iam_instance_profile   = aws_iam_instance_profile.spoke_vm_iam_instance_profile.name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    kms_key_id            = data.aws_kms_key.current.arn
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
  echo "200 OK" > /var/www/html/index.html
  EOF
}

### SPOKE INBOUND APPLICATION LOAD BALANCER ###

module "app_alb" {
  source = "../../modules/alb"

  for_each = var.spoke_albs

  lb_name         = "${var.name_prefix}${each.key}"
  subnets         = { for k, v in module.subnet_sets["${each.value.vpc}-${each.value.subnet_group}"].subnets : k => { id = v.id } }
  vpc_id          = module.vpc[each.value.vpc].id
  security_groups = [module.vpc[each.value.vpc].security_group_ids[each.value.security_groups]]
  rules           = each.value.rules
  targets         = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].private_ip }

  tags = var.global_tags
}

### SPOKE INBOUND NETWORK LOAD BALANCER ###

module "app_nlb" {
  source = "../../modules/nlb"

  for_each = var.spoke_nlbs

  name        = "${var.name_prefix}${each.value.name}"
  internal_lb = each.value.internal_lb
  subnets     = { for k, v in module.subnet_sets["${each.value.vpc}-${each.value.subnet_group}"].subnets : k => { id = v.id } }
  vpc_id      = module.subnet_sets["${each.value.vpc}-${each.value.subnet_group}"].vpc_id

  balance_rules = { for rule_key, rule_value in each.value.balance_rules : rule_key => {
    protocol    = rule_value.protocol
    port        = rule_value.port
    stickiness  = rule_value.stickiness
    target_type = "instance"
    targets     = { for vm in each.value.vms : vm => aws_instance.spoke_vms[vm].id }
  } }

  tags = var.global_tags
}