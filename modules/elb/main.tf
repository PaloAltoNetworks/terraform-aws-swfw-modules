# ## Access Logs Bucket ##
# For Application Load Balancers where access logs are stored in S3 Bucket.
# data "aws_s3_bucket" "this" {
#   count = var.access_logs_byob && var.configure_access_logs ? 1 : 0

#   bucket = var.access_logs_s3_bucket_name
# }

# resource "aws_s3_bucket" "this" {
#   count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

#   bucket        = var.access_logs_s3_bucket_name
#   force_destroy = true
# }

# resource "aws_s3_bucket_versioning" "this" {
#   count  = !var.access_logs_byob && var.configure_access_logs ? 1 : 0
#   bucket = aws_s3_bucket.this[0].id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
#   count  = !var.access_logs_byob && var.configure_access_logs ? 1 : 0
#   bucket = aws_s3_bucket.this[0].id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "aws:kms"
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "this" {
#   count  = !var.access_logs_byob && var.configure_access_logs ? 1 : 0
#   bucket = aws_s3_bucket.this[0].id

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_acl" "this" {
#   count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

#   bucket = aws_s3_bucket.this[0].id
#   acl    = "private"
# }

# data "aws_elb_service_account" "this" {}

# # Lookup information about the current AWS partition in which Terraform is working (e.g. `aws`, `aws-us-gov`, `aws-cn`)
# data "aws_partition" "this" {}

# data "aws_iam_policy_document" "this" {
#   count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

#   statement {
#     principals {
#       type        = "AWS"
#       identifiers = [data.aws_elb_service_account.this.arn]
#     }

#     actions = ["s3:PutObject"]

#     resources = ["arn:${data.aws_partition.this.partition}:s3:::${aws_s3_bucket.this[0].id}/${var.access_logs_s3_bucket_prefix != null ? "${var.access_logs_s3_bucket_prefix}/" : ""}AWSLogs/*"]
#   }
# }

# resource "aws_s3_bucket_policy" "this" {
#   count = !var.access_logs_byob && var.configure_access_logs ? 1 : 0

#   bucket = aws_s3_bucket.this[0].id
#   policy = data.aws_iam_policy_document.this[0].json
# }
# ######################## #

# ## Application Load Balancer ##
resource "aws_lb" "this" {
  name                             = var.lb_name
  internal                         = var.internal
  load_balancer_type               = var.load_balancer_type
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing

  security_groups            = var.security_groups

  subnets = var.subnets

  # dynamic "access_logs" {
  #   for_each = var.configure_access_logs ? [1] : []

  #   content {
  #     bucket  = var.access_logs_byob ? data.aws_s3_bucket.this[0].id : aws_s3_bucket.this[0].id
  #     prefix  = var.access_logs_s3_bucket_prefix
  #     enabled = true
  #   }
  # }

  tags = var.tags

  # depends_on = [
  #   aws_s3_bucket_policy.this[0]
  # ]
}
# ######################## #

# # ## Target Group Configuration ##

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name     = each.value.name
  port     = each.value.port
  protocol = each.value.protocol
  vpc_id   = each.value.vpc_id
  target_type = each.value.type
}

# # ## Listener Configuration ##
resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = try(each.value.port, each.value.protocol == "HTTP" ? "80" : "443")
  protocol          = each.value.protocol

  # HTTPS specific values
  certificate_arn = each.value.protocol == "HTTPS" ? try(each.value.certificate_arn, null) : null
  ssl_policy      = try(each.value.ssl_policy, null)

  # catch-all rule, if no listener rule matches
  dynamic "default_action" {
    for_each = each.value.forward != null ? [each.value.forward] : []
    content {
      type = "forward"
      target_group_arn = aws_lb_target_group.this[default_action.value.target_group_key].arn
    }
  }
  
  dynamic "default_action" {
    for_each = each.value.fixed_response != null ? [each.value.fixed_response] : []
    content {
      type = "fixed-response"
      fixed_response {
        content_type = try(default_action.value.content_type, "text/plain")
        status_code = try(default_action.value.status_code, "503")
        message_body = try(default_action.value.message_body, null)
      }
    }
  }
  dynamic "default_action" {
    for_each = each.value.redirect != null ? [each.value.redirect] : []

    content {
      order = try(default_action.value.order, null)

      redirect {
        host        = try(default_action.value.host, null)
        path        = try(default_action.value.path, null)
        port        = try(default_action.value.port, null)
        protocol    = try(default_action.value.protocol, null)
        query       = try(default_action.value.query, null)
        status_code = default_action.value.status_code
      }

      type = "redirect"
    }
  }

  tags = merge({ name : each.key }, var.tags)
}

locals {
  listener_rules = flatten([
    for listener_key, listener_values in var.listeners : [
      for rule_key, rule_values in lookup(listener_values, "rules", {}) :
      merge(rule_values, {
        listener_key = listener_key
        rule_key     = rule_key
      })
    ]
  ])
}

resource "aws_lb_listener_rule" "this" {
  for_each = { for v in local.listener_rules : "${v.listener_key}-${v.rule_key}" => v }

  listener_arn = aws_lb_listener.this[each.value.listener_key].arn
  priority = each.value.priority

  dynamic "action" {
    for_each = each.value.action.type == "forward" ? [ each.value.action ] : []
    
    content {
      type = "forward"
      target_group_arn = aws_lb_target_group.this[action.value.target_group_key].arn
    }

  }

  dynamic "condition" {
    for_each = [ { for ck, cv in each.value.conditions : ck => cv if ck == "path_pattern" } ]

    content {
      dynamic "path_pattern" {
        for_each = condition.value.path_pattern != null ? condition.value : {}
        content {
          values = path_pattern.value
        }
      }
    }
  }

    dynamic "condition" {
    for_each = [ { for ck, cv in each.value.conditions : ck => cv if ck == "host_header" } ]

    content {
      dynamic "host_header" {
        for_each = condition.value.host_header != null ? condition.value : {}
        content {
          values = host_header.value
        }
      }
    }
  }
}
