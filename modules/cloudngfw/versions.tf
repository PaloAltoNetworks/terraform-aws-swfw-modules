terraform {
  required_version = ">= 1.3.0, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.17"
    }
    cloudngfwaws = {
      source  = "PaloAltoNetworks/cloudngfwaws"
      version = "~> 2.0.17"
    }
  }
}
