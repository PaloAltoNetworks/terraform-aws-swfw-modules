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
     - `vpc` - VPC key
     - `subnet` - subnet key
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
          vpc           = "app1_vpc"
          subnet        = "app1_vm"
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
        from_port   = optional(string)
        to_port     = optional(string)
      }))
    }))
    security_groups = map(object({
      name = string
      rules = map(object({
        description = string
        type        = string
        from_port   = string
        to_port     = string
        protocol    = string
        cidr_blocks = list(string)
      }))
    }))
    subnets = map(object({
      az                      = string
      set                     = string
      nacl                    = optional(string)
      create_subnet           = optional(bool, true)
      create_route_table      = optional(bool, true)
      existing_route_table_id = optional(string)
      associate_route_table   = optional(bool, true)
      route_table_name        = optional(string)
      local_tags              = optional(map(string), {})
    }))
    routes = map(object({
      vpc           = string
      subnet        = string
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
  - `vpc`: key of the VPC
  - `subnet`: key of the subnet

  Example:
  ```
  natgws = {
    security_nat_gw = {
      name   = "natgw"
      vpc    = "security_vpc"
      subnet = "natgw"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name   = string
    vpc    = string
    subnet = string
  }))
}

variable "tgw" {
  description = <<-EOF
  A object defining Transit Gateway.

  Following properties are available:
  - `create`: set to false, if existing TGW needs to be reused
  - `id`:  id of existing TGW or null
  - `name`: name of TGW to create or use
  - `asn`: ASN number
  - `route_tables`: map of route tables
  - `attachments`: map of TGW attachments

  Example:
  ```
  tgw = {
    create = true
    id     = null
    name   = "tgw"
    asn    = "64512"
    route_tables = {
      "from_security_vpc" = {
        create = true
        name   = "from_security"
      }
    }
    attachments = {
      security = {
        name                = "vmseries"
        vpc                 = "security_vpc"
        subnet              = "tgw_attach"
        route_table         = "from_security_vpc"
        propagate_routes_to = ["from_spoke_vpc"]
      }
    }
  }
  ```
  EOF
  type = object({
    create = bool
    id     = string
    name   = string
    asn    = string
    route_tables = map(object({
      create = bool
      name   = string
    }))
    attachments = map(object({
      name                = string
      vpc                 = string
      subnet              = string
      route_table         = string
      propagate_routes_to = list(string)
    }))
  })
}

variable "gwlb_endpoints" {
  description = <<-EOF
  A map defining GWLB endpoints.

  Following properties are available:
  - `name`: name of the GWLB endpoint
  - `gwlb`: key of GWLB
  - `vpc`: key of VPC
  - `subnet`: key of the subnet
  - `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic
  - `from_igw_to_vpc`: VPC to which traffic from IGW is routed to the GWLB endpoint
  - `from_igw_to_subnet` : subnet to which traffic from IGW is routed to the GWLB endpoint

  Example:
  ```
  gwlb_endpoints = {
    security_gwlb_eastwest = {
      name            = "eastwest-gwlb-endpoint"
      gwlb            = "security_gwlb"
      vpc             = "security_vpc"
      subnet          = "gwlbe_eastwest"
      act_as_next_hop = false
      delay           = 60
      cloudngfw       = "cloudngfw"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name               = string
    vpc                = string
    subnet             = string
    act_as_next_hop    = bool
    from_igw_to_vpc    = optional(string)
    from_igw_to_subnet = optional(string)
    delay              = number
    cloudngfw          = string
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
      profile_config = {
        anti_spyware  = "BestPractice"
        anti_virus    = "BestPractice"
        vulnerability = "BestPractice"
        file_blocking = "BestPractice"
        url_filtering = "BestPractice"
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
    profile_config = map(any)
  }))
}

### SPOKE VMS
variable "spoke_vms" {
  description = <<-EOF
  A map defining VMs in spoke VPCs.

  Following properties are available:
  - `az`: name of the Availability Zone
  - `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)
  - `subnet`: key of the subnet
  - `security_group`: security group assigned to ENI used by VM
  - `type`: EC2 type VM

  Example:
  ```
  spoke_vms = {
    "app1_vm01" = {
      az             = "eu-central-1a"
      vpc            = "app1_vpc"
      subnet         = "app1_vm"
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
    subnet         = string
    security_group = string
    type           = string
  }))
}

### SPOKE LOADBALANCERS
variable "spoke_nlbs" {
  description = <<-EOF
  A map defining Network Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `vpc`: key of the VPC
  - `subnet`: key of the subnet
  - `vms`: keys of spoke VMs

  Example:
  ```
  spoke_lbs = {
    "app1-nlb" = {
      vpc    = "app1_vpc"
      subnet = "app1_lb"
      vms    = ["app1_vm01", "app1_vm02"]
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    vpc    = string
    subnet = string
    vms    = list(string)
  }))
}

variable "spoke_albs" {
  description = <<-EOF
  A map defining Application Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `rules`: Rules defining the method of traffic balancing
  - `vms`: Instances to be the target group for ALB
  - `vpc`: The VPC in which the load balancer is to be run
  - `subnet`: The subnets in which the Load Balancer is to be run
  - `security_gropus`: Security Groups to be associated with the ALB
  ```
  EOF
  type = map(object({
    rules           = any
    vms             = list(string)
    vpc             = string
    subnet          = string
    security_groups = string
  }))
}