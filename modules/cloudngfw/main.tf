data "aws_caller_identity" "current" {}

resource "cloudngfwaws_ngfw" "this" {
  name        = var.name
  vpc_id      = var.vpc_id
  account_id  = data.aws_caller_identity.current.id
  description = var.description

  endpoint_mode = "CustomerManaged"

  dynamic "subnet_mapping" {
    for_each = var.subnets

    content {
      #subnet_id = try(subnet_mapping.value.id, null)
      availability_zone = subnet_mapping.key
    }
  }

  rulestack = cloudngfwaws_commit_rulestack.this.rulestack

  tags = var.tags
}

resource "cloudngfwaws_commit_rulestack" "this" {
  rulestack = cloudngfwaws_rulestack.this.name
}

resource "cloudngfwaws_rulestack" "this" {
  name        = var.rulestack_name
  scope       = var.rulestack_scope #
  account_id  = data.aws_caller_identity.current.id
  description = var.description_rule

  profile_config {
    anti_spyware  = var.profile_config["anti_spyware"]
    anti_virus    = var.profile_config["anti_virus"]
    vulnerability = var.profile_config["vulnerability"]
    file_blocking = var.profile_config["file_blocking"]
    url_filtering = var.profile_config["url_filtering"]
  }
}

resource "cloudngfwaws_security_rule" "this" {
  for_each = var.security_rules

  rulestack = cloudngfwaws_rulestack.this.name

  rule_list   = each.value.rule_list
  priority    = each.value.priority
  name        = each.value.name
  description = each.value.description

  source {
    cidrs = each.value.source_cidrs
  }

  destination {
    cidrs = each.value.destination_cidrs
  }

  negate_destination = each.value.negate_destination
  protocol           = each.value.protocol
  applications       = each.value.applications

  category {
    feeds              = each.value.category_feeds
    url_category_names = each.value.category_url_category_names
  }

  action        = each.value.action
  logging       = each.value.logging
  audit_comment = each.value.audit_comment
}

resource "cloudngfwaws_ngfw_log_profile" "this" {
  ngfw       = cloudngfwaws_ngfw.this.name
  account_id = data.aws_caller_identity.current.id

  dynamic "log_destination" {
    for_each = var.log_profiles
    content {
      destination_type = log_destination.value.destination_type
      destination      = log_destination.value.destination_type == "CloudWatchLogs" ? aws_cloudwatch_log_group.this[log_destination.value.name].name : log_destination.value.name
      log_type         = log_destination.value.log_type
    }
  }
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(distinct([for _, v in var.log_profiles : v.name if v.create_cw]))

  name              = each.key
  retention_in_days = 90

  tags = var.tags
}

resource "aws_cloudwatch_log_stream" "this" {
  for_each = toset(distinct([for _, v in var.log_profiles : v.name if v.create_cw]))

  name           = each.key
  log_group_name = aws_cloudwatch_log_group.this[each.key].name
}