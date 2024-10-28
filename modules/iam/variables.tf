variable "name_prefix" {
  description = "Prefix used in names for the resources. (IAM Role, Instance Profile)"
  type        = string
}

variable "tags" {
  description = "Global tags configured for all provisioned resources."
  type        = map(any)
}

variable "region" {
  description = "AWS region where SSM or CloudWatch is located."
  type        = string
  default     = null
}

variable "principal_role" {
  description = "The type of entity that can take actions in AWS."
  type        = string
  default     = "ec2.amazonaws.com"
}

variable "create_role" {
  description = "Create a dedicated role creation of pre-defined policies."
  type        = bool
  default     = true
}

variable "role_name" {
  description = "A role name, required for the service."
  type        = string
}

variable "create_instance_profile" {
  description = "Create an instance profile."
  type        = bool
  default     = false
}

variable "instance_profile_name" {
  description = "Instance profile name."
  type        = string
  default     = null
}

variable "create_lambda_policy" {
  description = "Create a pre-defined lambda policies for ASG."
  type        = bool
  default     = false
}

variable "create_vmseries_policy" {
  description = "Create a pre-defined vmseries policy."
  type        = bool
  default     = false
}

variable "create_bootrap_policy" {
  description = "Create a pre-defined bootstrap policy."
  type        = bool
  default     = false
}

variable "policy_arn" {
  description = "The AWS or Customer managed policy arn. It should be used for spoke VM scenario using the AWS managed ```arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore``` policy."
  type        = string
  default     = null
}

variable "custom_policy" {
  description = <<-EOF
  A custom lambda policy. Multi-statement is supported.
  Basic example:
  ```
    statement1 = {
      sid    = "1"
      effect = "Allow"
      actions = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      resources = [
        "arn:*:logs:*:*:*"
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
        values   = "user1"
      }
    }
  ```
  EOF
  type = map(object({
    sid       = string
    effect    = string
    actions   = list(string)
    resources = list(string)
    condition = optional(object({
      test     = string
      variable = string
      values   = list(string)
    }))
  }))
  default = null
}

variable "delicense_ssm_param_name" {
  description = <<-EOF
  Required for IAM de-licensing permissions.
  String in Parameter Store with value in below format:
  ```
  {"username":"ACCOUNT","password":"PASSWORD","panorama1":"IP_ADDRESS1","panorama2":"IP_ADDRESS2","license_manager":"LICENSE_MANAGER_NAME"}"
  ```
  the format can either be the plain name in case you store it without hierarchy or with a "/" in case you store in in a hierarchy
  EOF
  default     = null
  type        = string
}

variable "aws_s3_bucket" {
  description = "Name of the s3 bucket, that is required and used for ```var.create_bootrap_policy```."
  default     = null
  type        = string
}
