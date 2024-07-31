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
variable "tags" {
  description = "Tags configured for all provisioned resources"
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
  - `cidr_block`: Object containing the IPv4 and IPv6 CIDR blocks to assign to a new VPC
  - `subnets`: map of subnets with properties
  - `routes`: map of routes with properties
  - `nacls`: map of network ACLs
  - `security_groups`: map of security groups

  Example:
  ```
  vpcs = {
    app1_vpc = {
      name = "app1-spoke-vpc"
      cidr_block = {
        ipv4 = "10.104.0.0/16"
      }
      subnets = {
        app1_vma    = { az = "a", cidr_block = "10.104.0.0/24", subnet_group = "app1_vm", name = "app1_vm1" }
        app1_vmb    = { az = "b", cidr_block = "10.104.128.0/24", subnet_group = "app1_vm", name = "app1_vm2" }
        app1_lba    = { az = "a", cidr_block = "10.104.2.0/24", subnet_group = "app1_lb", name = "app1_lb1" }
        app1_lbb    = { az = "b", cidr_block = "10.104.130.0/24", subnet_group = "app1_lb", name = "app1_lb2" }
        app1_gwlbea = { az = "a", cidr_block = "10.104.3.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe1" }
        app1_gwlbeb = { az = "b", cidr_block = "10.104.131.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe2" }
      }
      routes = {
        vm_default = {
          vpc           = "app1_vpc"
          subnet_group  = "app1_vm"
          to_cidr       = "0.0.0.0/0"
          next_hop_key  = "app1"
          next_hop_type = "transit_gateway_attachment"
        }
        gwlbe_default = {
          vpc           = "app1_vpc"
          subnet_group  = "app1_gwlbe"
          to_cidr       = "0.0.0.0/0"
          next_hop_key  = "app1_vpc"
          next_hop_type = "internet_gateway"
        }
        lb_default = {
          vpc           = "app1_vpc"
          subnet_group  = "app1_lb"
          to_cidr       = "0.0.0.0/0"
          next_hop_key  = "app1_inbound"
          next_hop_type = "gwlbe_endpoint"
        }
      }
      nacls = {}
      security_groups = {
        app1_vm = {
          name = "app1_vm"
          rules = {
            all_outbound = {
              description = "Permit All traffic outbound"
              type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
              cidr_blocks = ["0.0.0.0/0"]
            }
            ssh = {
              description = "Permit SSH"
              type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"]
            }
            https = {
              description = "Permit HTTPS"
              type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"]
            }
            http = {
              description = "Permit HTTP"
              type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
              cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"]
            }
          }
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name = string
    cidr_block = object({
      ipv4                  = optional(string)
      secondary_ipv4        = optional(list(string), [])
      assign_generated_ipv6 = optional(bool, false)
    })
    nacls = map(object({
      name = string
      rules = map(object({
        rule_number = number
        type        = string
        protocol    = string
        action      = string
        cidr_block  = string
        from_port   = optional(string)
        to_port     = optional(string)
      }))
    }))
    security_groups = map(object({
      name        = string
      description = optional(string, "Security group managed by Terraform")
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
      subnet_group            = string
      az                      = string
      name                    = string
      cidr_block              = string
      ipv6_cidr_block         = optional(string)
      nacl                    = optional(string)
      create_subnet           = optional(bool, true)
      create_route_table      = optional(bool, true)
      existing_route_table_id = optional(string)
      associate_route_table   = optional(bool, true)
      route_table_name        = optional(string)
      local_tags              = optional(map(string), {})
      tags                    = optional(map(string), {})
    }))
    routes = map(object({
      vpc           = string
      subnet_group  = string
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
  - `subnet_group`: key of the subnet_group

  Example:
  ```
  natgws = {
    security_nat_gw = {
      name         = "natgw"
      vpc          = "security_vpc"
      subnet_group = "natgw"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name         = string
    vpc          = string
    subnet_group = string
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
        subnet_group        = "tgw_attach"
        route_table         = "from_security_vpc"
        propagate_routes_to = "from_spoke_vpc"
      }
    }
  }
  ```
  EOF
  default     = null
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
      subnet_group        = string
      route_table         = string
      propagate_routes_to = string
    }))
  })
}

variable "gwlb_endpoints" {
  description = <<-EOF
  A map defining GWLB endpoints.

  Following properties are available:
  - `name`: name of the GWLB endpoint
  - `vpc`: key of VPC
  - `subnet_group`: key of the subnet_group
  - `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic
  - `from_igw_to_vpc`: VPC to which traffic from IGW is routed to the GWLB endpoint
  - `from_igw_to_subnet_group` : subnet_group to which traffic from IGW is routed to the GWLB endpoint
  - `delay`: delay in seconds for the endpoint
  - `cloudngfw`: key of the Cloud NGFW

  Example:
  ```
  gwlb_endpoints = {
    security_gwlb_eastwest = {
      name            = "eastwest-gwlb-endpoint"
      vpc             = "security_vpc"
      subnet_group    = "gwlbe_eastwest"
      act_as_next_hop = false
      delay           = 60
      cloudngfw       = "cloudngfw"
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name                     = string
    vpc                      = string
    subnet_group             = string
    act_as_next_hop          = bool
    from_igw_to_vpc          = optional(string)
    from_igw_to_subnet_group = optional(string)
    delay                    = number
    cloudngfw                = string
  }))
}

### CLOUD NGFW
variable "cloudngfws" {
  description = <<-EOF
  A map defining Cloud NGFWs.

  Following properties are available:
  - `name`          : name of CloudNGFW
  - `vpc`           : key of the VPC
  - `subnet_group`  : group of subnets
  - `description`   : Use for internal purposes.
  - `security_rules`: Security Rules definition.
  - `log_profiles`  : Log Profile definition.

  Example:
  ```
  cloudngfws = {
    cloudngfws_security = {
      name         = "cloudngfw01"
      vpc          = "app_vpc"
      subnet_group = "app_gwlbe"
      description  = "description"
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
    vpc            = string
    subnet_group   = string
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
  - `subnet_group`: key of the subnet_group
  - `security_group`: security group assigned to ENI used by VM
  - `type`: EC2 type VM

  Example:
  ```
  spoke_vms = {
    "app1_vm01" = {
      az             = "eu-central-1a"
      vpc            = "app1_vpc"
      subnet_group   = "app1_vm"
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
    subnet_group   = string
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
  - `subnet_group`: key of the subnet_group
  - `vms`: keys of spoke VMs

  Example:
  ```
  spoke_lbs = {
    "app1-nlb" = {
      vpc          = "app1_vpc"
      subnet_group = "app1_lb"
      vms          = ["app1_vm01", "app1_vm02"]
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    vpc          = string
    subnet_group = string
    vms          = list(string)
  }))
}

variable "spoke_albs" {
  description = <<-EOF
  A map defining Application Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `rules`: Rules defining the method of traffic balancing
  - `vms`: Instances to be the target group for ALB
  - `vpc`: The VPC in which the load balancer is to be run
  - `subnet_group`: The subnet_groups in which the Load Balancer is to be run
  - `security_gropus`: Security Groups to be associated with the ALB
  ```
  EOF
  type = map(object({
    rules           = any
    vms             = list(string)
    vpc             = string
    subnet_group    = string
    security_groups = string
  }))
}