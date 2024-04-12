variable "name" {
  description = "Name of the Cloud NGFW instance."

  type = string
}

variable "vpc_id" {
  description = "ID of the security VPC the Load Balancer should be created in."
  type        = string
}

variable "description" {
  description = "Cloud NGFW description."
  default     = "CloudNGFW"
  type        = string
}

variable "subnets" {
  description = <<-EOF
  Map of Subnets where to create the NAT Gateways. Each map's key is the availability zone name and each map's object has an attribute `id` identifying AWS Subnet. Importantly, the traffic returning from the NAT Gateway uses the Subnet's route table.
  The keys of this input map are used for the output map `endpoints`.
  Example for users of module `subnet_set`:
  ```
  subnets = module.subnet_set.subnets
  ```
  Example:
  ```
  subnets = {
    "us-east-1a" = { id = "snet-123007" }
    "us-east-1b" = { id = "snet-123008" }
  }
  ```
  EOF
  type = map(object({
    id   = string
    tags = map(string)
  }))
}

variable "rulestack_name" {
  description = "The rulestack name."
  type        = string
}

variable "rulestack_scope" {
  description = "The rulestack scope. A local rulestack will require that you've retrieved a LRA JWT. A global rulestack will require that you've retrieved a GRA JWT"
  default     = "Local"
  type        = string
}

variable "description_rule" {
  description = "The rulestack description."
  default     = "CloudNGFW rulestack"
  type        = string
}

variable "profile_config" {
  description = "The rulestack profile config."
  default     = {}
  type        = map(any)
}

variable "security_rules" {
  description = <<-EOF
  Example:
  ```
  security_rules = {
    rule_1 = {
      rule_list                   = "LocalRule"
      priority                    = 3
      name                        = "tf-security-rule"
      description                 = "Also configured by Terraform"
      source_cidrs                = ["any"]
      destination_cidrs           = ["0.0.0.0/0"]
      negate_destination          = false
      protocol                    = "application-default"
      applications                = ["any"]
      category_feeds              = [""]
      category_url_category_names = [""]
      action                      = "Allow"
      logging                     = true
      audit_comment               = "initial config"
    }
  }
  ```
  EOF
  default     = {}
  # For now it's not possible to have a more strict definition of variable type, optional
  # object attributes are still experimental
  type = map(object({
    rule_list                   = string
    priority                    = number
    name                        = string
    description                 = string
    source_cidrs                = set(string)
    destination_cidrs           = set(string)
    negate_destination          = bool
    protocol                    = string
    applications                = set(string)
    category_feeds              = set(string)
    category_url_category_names = set(string)
    action                      = string
    logging                     = bool
    audit_comment               = string
  }))
}

variable "log_profiles" {
  description = <<-EOF
  The CloudWatch logs group name should correspond with the assumed role generated in cfn.
  - `aws_cloudwatch_log_group`  = (Required|string)
  - `aws_cloudwatch_log_stream` = (Required|string)
  - `destination_type`          = (Required|string)
  - `log_type`                  = (Required|string)
  Example:
  ```
  log_profiles = {
    aws_cloudwatch_log_group  = "PaloAltoCloudNGFW"
    aws_cloudwatch_log_stream = "PaloAltoCloudNGFW"

    dest_1 = {
      destination_type = "CloudWatchLogs"
      log_type         = "THREAT"
    }
    dest_2 = {
      destination_type = "CloudWatchLogs"
      log_type         = "TRAFFIC"
    }
    dest_3 = {
      destination_type = "CloudWatchLogs"
      log_type         = "DECRYPTION"
    }
  }
  ```
  EOF
  default     = {}
  # For now it's not possible to have a more strict definition of variable type, optional
  # object attributes are still experimental
  type = map(any)
}

variable "endpoint_mode" {
  description = "The endpoint mode indicate the creation method of endpoint for target VPC. Customer Managed required to create endpoint manually."
  default     = "CustomerManaged"
  type        = string
}

variable "retention_in_days" {
  description = "CloudWatch log groups retains logs."
  default     = 365
  type        = number
}

variable "tags" {
  description = "AWS Tags for the VPC Endpoints."
  default     = {}
  type        = map(string)
}
