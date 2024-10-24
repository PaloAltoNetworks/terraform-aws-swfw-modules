### IAM ROLES AND POLICIES ###

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

locals {
  account_id      = data.aws_caller_identity.this.account_id
  delicense_param = try(startswith(var.delicense_ssm_param_name, "/") ? var.delicense_ssm_param_name : "/${var.delicense_ssm_param_name}", null)

  lambda_execute_policy = {
    statement1 = {
      sid    = "1"
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = [
        "arn:${data.aws_partition.this.partition}:logs:*:*:*"
      ]
    }
    statement2 = {
      sid    = "2"
      effect = "Allow"
      actions = [
        "ec2:AllocateAddress",
        "ec2:AssociateAddress",
        "ec2:AttachNetworkInterface",
        "ec2:CreateNetworkInterface",
        "ec2:CreateTags",
        "ec2:DescribeAddresses",
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeTags",
        "ec2:DescribeSubnets",
        "ec2:DeleteNetworkInterface",
        "ec2:DeleteTags",
        "ec2:DetachNetworkInterface",
        "ec2:DisassociateAddress",
        "ec2:ModifyNetworkInterfaceAttribute",
        "ec2:ReleaseAddress",
        "autoscaling:CompleteLifecycleAction",
        "autoscaling:DescribeAutoScalingGroups",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets"
      ]

      resources = ["*"]

      condition = {
        test     = "StringEquals"
        variable = "aws:ResourceTag/Owner"
        values   = [var.global_tags["Owner"]]
      }
    }
    statement3 = {
      sid    = "3"
      effect = "Allow"
      actions = [
        "ec2:DescribeAddresses",
        "ec2:DescribeInstances",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeTags",
        "ec2:DescribeSubnets",
      ]

      resources = ["*"]
    }
    statement4 = {
      sid    = "4"
      effect = "Allow"
      actions = [
        "kms:GenerateDataKey*",
        "kms:Decrypt",
        "kms:CreateGrant"
      ]

      resources = ["*"]

      condition = {
        test     = "StringEquals"
        variable = "aws:ResourceTag/Owner"
        values   = [var.global_tags["Owner"]]
      }
    }
  }

  lambda_delicense_policy = {
    statement1 = {
      sid    = "1"
      effect = "Allow"
      actions = [
        "ssm:DescribeParameters",
        "ssm:GetParametersByPath",
        "ssm:GetParameter",
        "ssm:GetParameterHistory"
      ]

      resources = [
        "arn:${data.aws_partition.this.partition}:ssm:${var.region}:${local.account_id}:parameter${local.delicense_param}"
      ]
    }
  }

  vmseries_policy = {
    statement1 = {
      sid    = "1"
      effect = "Allow"
      actions = [
        "cloudwatch:PutMetricData",
        "cloudwatch:GetMetricData",
        "cloudwatch:ListMetrics"
      ]

      resources = [
        "*"
      ]
    }
    statement2 = {
      sid    = "2"
      effect = "Allow"
      actions = [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DescribeAlarms"
      ]

      resources = [
        "arn:${data.aws_partition.this.partition}:cloudwatch:${var.region}:${data.aws_caller_identity.this.account_id}:alarm:*"
      ]
    }
  }

  bootstrap_policy = {
    statement1 = {
      sid       = "1"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["arn:${data.aws_partition.this.partition}:s3:::${var.aws_s3_bucket}"]
    }
    statement2 = {
      sid       = "2"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = ["arn:${data.aws_partition.this.partition}:s3:::${var.aws_s3_bucket}/*"]
    }
  }

  aws_policies = {
    "custom" = {
      enable     = var.custom_policy == null ? false : true
      definition = try(var.custom_policy, null)
    },
    "lambda_execute" = {
      enable     = var.create_lambda_policy ? true : false
      definition = try(local.lambda_execute_policy, null)
    },
    "lambda_delicense" = {
      enable     = var.create_lambda_policy && var.delicense_ssm_param_name != null ? true : false
      definition = try(local.lambda_delicense_policy, null)
    },
    "vmseries" = {
      enable     = var.create_vmseries_policy
      definition = try(local.vmseries_policy, null)
    },
    "bootstrap" = {
      enable     = var.create_bootrap_policy && var.aws_s3_bucket != null ? true : false
      definition = try(local.bootstrap_policy, null)
    }
  }
}

data "aws_iam_policy_document" "this" {
  for_each = { for k, v in local.aws_policies : k => v if v.enable == true }

  dynamic "statement" {
    for_each = each.value.definition
    content {
      sid       = statement.value["sid"]
      effect    = statement.value["effect"]
      resources = statement.value["resources"]
      actions   = statement.value["actions"]
      dynamic "condition" {
        for_each = lookup(statement.value, "condition", {}) != {} ? [1] : []
        content {
          test     = try(statement.value["condition"]["test"], null)
          variable = try(statement.value["condition"]["variable"], null)
          values   = try(statement.value["condition"]["values"], null)
        }
      }
    }
  }
}

resource "aws_iam_role" "this" {
  count              = var.create_role ? 1 : 0
  name               = "${var.name_prefix}${var.role_name}"
  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "${var.principal_role}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = var.policy_arn == null ? 0 : 1
  role       = aws_iam_role.this[0].name
  policy_arn = var.policy_arn
}

resource "aws_iam_role_policy" "this" {
  for_each = data.aws_iam_policy_document.this

  name   = "${var.name_prefix}${each.key}"
  role   = aws_iam_role.this[0].id
  policy = each.value.json
}

resource "aws_iam_instance_profile" "this" {
  count = var.create_instance_profile ? 1 : 0
  name  = "${var.name_prefix}${var.profile_instance_name}"
  role  = aws_iam_role.this[0].name
}