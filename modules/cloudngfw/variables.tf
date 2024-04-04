variable "name" {
  description = "Name of the VM-Series instance."
  type        = string
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
  default = {
    anti_spyware  = "BestPractice"
    anti_virus    = "BestPractice"
    vulnerability = "BestPractice"
    file_blocking = "BestPractice"
    url_filtering = "BestPractice"
  }
  type = map(any)
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
  # For now it's not possible to have a more strict definition of variable type, optional
  # object attributes are still experimental
  type = map(any)
}

variable "log_profiles" {
  description = <<-EOF
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
  # For now it's not possible to have a more strict definition of variable type, optional
  # object attributes are still experimental
  type = map(any)
}

variable "tags" {
  description = "AWS Tags for the VPC Endpoints."
  default     = {}
  type        = map(string)
}
