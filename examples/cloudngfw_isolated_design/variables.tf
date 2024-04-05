### Provider
variable "provider_account" {
  description = "The AWS Account where the resources should be deployed."
  type        = string
}
variable "provider_role" {
  description = "The predifined AWS assumed role for CloudNGFW."
  type        = string
}

### GENERAL
variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}
variable "name_prefix" {
  description = "Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.)"
  type        = string
}
variable "global_tags" {
  description = "Global tags configured for all provisioned resources"
}
variable "ssh_key_name" {
  description = "Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes"
  type        = string
}
### VPC
variable "vpcs" {
  description = <<-EOF
  A map defining VPCs with security groups and subnets.

  Following properties are available:
  - `name`: VPC name
  - `cidr`: CIDR for VPC
  - `nacls`: map of network ACLs
  - `security_groups`: map of security groups
  - `subnets`: map of subnets with properties:
     - `az`: availability zone
     - `set`: internal identifier referenced by main.tf
     - `nacl`: key of NACL (can be null)
  - `routes`: map of routes with properties:
     - `vpc_subnet` - built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
     - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
     - `next_hop_type` - internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint

  Example:
  ```
  vpcs = {
    example_vpc = {
      name = "example-spoke-vpc"
      cidr = "10.104.0.0/16"
      nacls = {
        trusted_path_monitoring = {
          name               = "trusted-path-monitoring"
          rules = {
            allow_inbound = {
              rule_number = 300
              egress      = false
              protocol    = "-1"
              rule_action = "allow"
              cidr_block  = "0.0.0.0/0"
              from_port   = null
              to_port     = null
            }
          }
        }
      }
      security_groups = {
        example_vm = {
          name = "example_vm"
          rules = {
            all_outbound = {
              description = "Permit All traffic outbound"
              type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
              cidr_blocks = ["0.0.0.0/0"]
            }
          }
        }
      }
      subnets = {
        "10.104.0.0/24"   = { az = "eu-central-1a", set = "vm", nacl = null }
        "10.104.128.0/24" = { az = "eu-central-1b", set = "vm", nacl = null }
      }
      routes = {
        vm_default = {
          vpc_subnet    = "app1_vpc-app1_vm"
          to_cidr       = "0.0.0.0/0"
          next_hop_key  = "app1"
          next_hop_type = "transit_gateway_attachment"
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name = string
    cidr = string
    nacls = map(object({
      name = string
      rules = map(object({
        rule_number = number
        egress      = bool
        protocol    = string
        rule_action = string
        cidr_block  = string
        from_port   = string
        to_port     = string
      }))
    }))
    security_groups = any
    subnets = map(object({
      az   = string
      set  = string
      nacl = string
    }))
    routes = map(object({
      vpc_subnet    = string
      to_cidr       = string
      next_hop_key  = string
      next_hop_type = string
    }))
  }))
}

variable "natgws" {
  description = <<-EOF
  A map defining NAT Gateways.

  Following properties are available:
  - `name`: name of NAT Gateway
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character

  Example:
  ```
  natgws = {
    security_nat_gw = {
      name       = "natgw"
      vpc_subnet = "security_vpc-natgw"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name       = string
    vpc_subnet = string
  }))
}

### SPOKE VMS
variable "spoke_vms" {
  description = <<-EOF
  A map defining VMs in spoke VPCs.

  Following properties are available:
  - `az`: name of the Availability Zone
  - `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `security_group`: security group assigned to ENI used by VM
  - `type`: EC2 type VM

  Example:
  ```
  spoke_vms = {
    "app1_vm01" = {
      az             = "eu-central-1a"
      vpc            = "app1_vpc"
      vpc_subnet     = "app1_vpc-app1_vm"
      security_group = "app1_vm"
      type           = "t2.micro"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    az             = string
    vpc            = string
    vpc_subnet     = string
    security_group = string
    type           = string
  }))
}

### SPOKE LOADBALANCERS
variable "spoke_nlbs" {
  description = <<-EOF
  A map defining Network Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `vms`: keys of spoke VMs

  Example:
  ```
  spoke_lbs = {
    "app1-nlb" = {
      vpc_subnet = "app1_vpc-app1_lb"
      vms        = ["app1_vm01", "app1_vm02"]
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    vpc_subnet = string
    vms        = list(string)
  }))
}

variable "spoke_albs" {
  description = <<-EOF
  A map defining Application Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `rules`: Rules defining the method of traffic balancing
  - `vms`: Instances to be the target group for ALB
  - `vpc`: The VPC in which the load balancer is to be run
  - `vpc_subnet`: The subnets in which the Load Balancer is to be run
  - `security_gropus`: Security Groups to be associated with the ALB
  ```
  EOF
  type = map(object({
    rules           = any
    vms             = list(string)
    vpc             = string
    vpc_subnet      = string
    security_groups = string
  }))
}

variable "cloudngfws" {
  description = <<-EOF
  A map defining Cloud NGFWs.

  Following properties are available:
  - `name`       : name of CloudNGFW
  - `vpc_subnet` : key of the VPC and subnet connected by '-' character
  - `vpc`        : key of the VPC
  - `description`: Use for internal purposes.
  - `security_rules`: Security Rules definition.
  - `log_profiles`: Log Profile definition.

  Example:
  ```
  cloudngfws = {
    cloudngfws_security = {
      name        = "cloudngfw01"
      vpc_subnet  = "app_vpc-app_gwlbe"
      vpc         = "app_vpc"
      description = "description"
      security_rules = 
      { 
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
          category_feeds              = null
          category_url_category_names = null
          action                      = "Allow"
          logging                     = true
          audit_comment               = "initial config"
        }
      }
      log_profiles = {  
        dest_1 = {
          create_cw        = true
          name             = "PaloAltoCloudNGFW"
          destination_type = "CloudWatchLogs"
          log_type         = "THREAT"
        }
        dest_2 = {
          create_cw        = true
          name             = "PaloAltoCloudNGFW"
          destination_type = "CloudWatchLogs"
          log_type         = "TRAFFIC"
        }
        dest_3 = {
          create_cw        = true
          name             = "PaloAltoCloudNGFW"
          destination_type = "CloudWatchLogs"
          log_type         = "DECRYPTION"
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name           = string
    vpc_subnet     = string
    vpc            = string
    description    = string
    security_rules = map(any)
    log_profiles   = map(any)
  }))
}


variable "gwlb_endpoints" {
  description = <<-EOF
  A map defining GWLB endpoints.

  Following properties are available:
  - `name`: name of the GWLB endpoint
  - `vpc`: key of VPC
  - `vpc_subnet`: key of the VPC and subnet connected by '-' character
  - `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic
  - `to_vpc_subnets`: subnets to which traffic from IGW is routed to the GWLB endpoint
  - `delay`: number of seconds between adding endpoint to routing table
  - `cloudngfw`: key of the cloudngfw correspond with the endpoints

  Example:
  ```
  gwlb_endpoints = {
    security_gwlb_eastwest = {
      name            = "eastwest-gwlb-endpoint"
      vpc             = "security_vpc"
      vpc_subnet      = "security_vpc-gwlbe_eastwest"
      act_as_next_hop = false
      to_vpc_subnets  = null
      delay           = 60
      cloudngfw       = "cloudngfw"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name            = string
    vpc             = string
    vpc_subnet      = string
    act_as_next_hop = bool
    to_vpc_subnets  = string
    delay           = number
    cloudngfw       = string
  }))
}
