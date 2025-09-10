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
  default     = ""
}
### VPC
variable "vpcs" {
  description = <<-EOF
    A map defining VPCs with security groups and subnets.

    Following properties are available:
    - `name`: VPC name
    - `cidr`: CIDR for VPC
    - `security_groups`: map of security groups
    - `subnets`: map of subnets with properties:
        - `az`: availability zone
        - `subnet_group`: identity of the same purpose subnets group such as management
    - `routes`: map of routes with properties:
        - `vpc`: key of the VPC
        - `subnet_group`: key of the subnet group
        - `next_hop_key`: must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
        - `next_hop_type`: internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint

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
          "10.104.0.0/24"   = { az = "eu-central-1a", subnet_group = "vm", nacl = null }
          "10.104.128.0/24" = { az = "eu-central-1b", subnet_group = "vm", nacl = null }
        }
        routes = {
          vm_default = {
            vpc           = "app1_vpc"
            subnet_group        = "app1_vm"
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
    name                             = string
    create_vpc                       = optional(bool, true)
    cidr                             = string
    secondary_cidr_blocks            = optional(list(string), [])
    assign_generated_ipv6_cidr_block = optional(bool)
    use_internet_gateway             = optional(bool, false)
    name_internet_gateway            = optional(string)
    create_internet_gateway          = optional(bool, true)
    route_table_internet_gateway     = optional(string)
    create_vpn_gateway               = optional(bool, false)
    vpn_gateway_amazon_side_asn      = optional(string)
    name_vpn_gateway                 = optional(string)
    route_table_vpn_gateway          = optional(string)
    enable_dns_hostnames             = optional(bool, true)
    enable_dns_support               = optional(bool, true)
    instance_tenancy                 = optional(string, "default")
    nacls = optional(map(object({
      name = string
      rules = map(object({
        rule_number = number
        egress      = bool
        protocol    = string
        rule_action = string
        cidr_block  = string
        from_port   = optional(number)
        to_port     = optional(number)
      }))
    })), {})
    security_groups = optional(map(object({
      name = string
      rules = map(object({
        description            = optional(string)
        type                   = string
        cidr_blocks            = optional(list(string))
        ipv6_cidr_blocks       = optional(list(string))
        from_port              = string
        to_port                = string
        protocol               = string
        prefix_list_ids        = optional(list(string))
        source_security_groups = optional(list(string))
        self                   = optional(bool)
      }))
    })), {})
    subnets = optional(map(object({
      name                    = optional(string, "")
      az                      = string
      subnet_group            = string
      nacl                    = optional(string)
      create_subnet           = optional(bool, true)
      create_route_table      = optional(bool, true)
      existing_route_table_id = optional(string)
      route_table_name        = optional(string)
      associate_route_table   = optional(bool, true)
      local_tags              = optional(map(string), {})
      map_public_ip_on_launch = optional(bool, false)
    })), {})
    routes = optional(map(object({
      vpc                    = string
      subnet_group           = string
      to_cidr                = string
      next_hop_key           = string
      next_hop_type          = string
      destination_type       = optional(string, "ipv4")
      managed_prefix_list_id = optional(string)
    })), {})
    create_dhcp_options = optional(bool, false)
    domain_name         = optional(string)
    domain_name_servers = optional(list(string))
    ntp_servers         = optional(list(string))
    vpc_tags            = optional(map(string), {})
  }))
}

### NAT GATEWAY
variable "natgws" {
  description = <<-EOF
  A map defining NAT Gateways.

  Following properties are available:
  - `nat_gateway_names`: A map, where each key is an Availability Zone name, for example "eu-west-1b". 
    Each value in the map is a custom name of a NAT Gateway in that Availability Zone.
  - `vpc`: key of the VPC
  - `subnet_group`: key of the subnet_group
  - `nat_gateway_tags`: A map containing NAT GW tags
  - `create_eip`: Defaults to true, uses a data source to find EIP when set to false
  - `eips`: Optional map of Elastic IP attributes. Each key must be an Availability Zone name. 

  Example:
  ```
  natgws = {
    sec_natgw = {
      vpc = "security_vpc"
      subnet_group = "natgw"
      nat_gateway_names = {
        "eu-west-1a" = "nat-gw-1"
        "eu-west-1b" = "nat-gw-2"
      }
      eips ={
        "eu-west-1a" = { 
          name = "natgw-1-pip"
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    create_nat_gateway = optional(bool, true)
    nat_gateway_names  = optional(map(string), {})
    vpc                = string
    subnet_group       = string
    nat_gateway_tags   = optional(map(string), {})
    create_eip         = optional(bool, true)
    eips = optional(map(object({
      name      = optional(string)
      public_ip = optional(string)
      id        = optional(string)
      eip_tags  = optional(map(string), {})
    })), {})
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
  - `type`: EC2 VM type

  Example:
  ```
  spoke_vms = {
    "app1_vm01" = {
      az             = "eu-central-1a"
      vpc            = "app1_vpc"
      subnet_group         = "app1_vm"
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
    type           = optional(string, "t3.micro")
  }))
}

### SPOKE LOADBALANCERS
variable "spoke_nlbs" {
  description = <<-EOF
  A map defining Network Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `name`: Name of the NLB
  - `vpc`: key of the VPC
  - `subnet_group`: key of the subnet_group
  - `vms`: keys of spoke VMs
  - `internal_lb`(optional): flag to switch between internet_facing and internal NLB
  - `balance_rules` (optional): Rules defining the method of traffic balancing 

  Example:
  ```
  spoke_lbs = {
    "app1-nlb" = {
      vpc    = "app1_vpc"
      subnet_group = "app1_lb"
      vms    = ["app1_vm01", "app1_vm02"]
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name         = string
    vpc          = string
    subnet_group = string
    vms          = list(string)
    internal_lb  = optional(bool, false)
    balance_rules = map(object({
      protocol   = string
      port       = string
      stickiness = optional(bool, true)
    }))
  }))
}

variable "spoke_albs" {
  description = <<-EOF
  A map defining Application Load Balancers deployed in spoke VPCs.

  Following properties are available:
  - `rules`: Rules defining the method of traffic balancing
  - `vms`: Instances to be the target group for ALB
  - `vpc`: The VPC in which the load balancer is to be run
  - `subnet_group`: The subnets in which the Load Balancer is to be run
  - `security_gropus`: Security Groups to be associated with the ALB
  ```
  EOF
  default     = {}
  type = map(object({
    rules = map(object({
      protocol              = optional(string, "HTTP")
      port                  = optional(number, 80)
      health_check_port     = optional(string, "80")
      health_check_matcher  = optional(string, "200")
      health_check_path     = optional(string, "/")
      health_check_interval = optional(number, 10)
      listener_rules = map(object({
        target_protocol = string
        target_port     = number
        path_pattern    = list(string)
      }))
    }))
    vms             = list(string)
    vpc             = string
    subnet_group    = string
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
    subnet_group   = string
    vpc            = string
    description    = optional(string, "Palo Alto Cloud NGFW")
    security_rules = map(any)
    log_profiles   = map(any)
    profile_config = map(any)
  }))
}

variable "gwlb_endpoints" {
  description = <<-EOF
    A map defining GWLB endpoints.

    Following properties are available:
    - `name`: name of the GWLB endpoint
    - `custom_names`: Optional map of names of the VPC Endpoints, used to override the default naming generated from the input `name`.
      Each key is the Availability Zone identifier, for example `us-east-1b`.
    - `gwlb`: key of GWLB. Required when GWLB Endpoint must connect to GWLB's service name
    - `vpc`: key of VPC
    - `subnet_group`: key of the subnet_group
    - `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic
    - `from_igw_to_vpc`: VPC to which traffic from IGW is routed to the GWLB endpoint
    - `from_igw_to_subnet_group` : subnet_group to which traffic from IGW is routed to the GWLB endpoint
    - `cloudngfw_key`(optional): Key of the Cloud NGFW. Required when GWLB Endpoint must connect to Cloud NGFW's service name

    Example:
    ```
    gwlb_endpoints = {
      security_gwlb_eastwest = {
        name            = "eastwest-gwlb-endpoint"
        gwlb            = "security_gwlb"
        vpc             = "security_vpc"
        subnet_group    = "gwlbe_eastwest"
        act_as_next_hop = false
      }
    }
    ```
    EOF
  default     = {}
  type = map(object({
    name                     = string
    custom_names             = optional(map(string), {})
    gwlb                     = optional(string)
    vpc                      = string
    subnet_group             = string
    act_as_next_hop          = bool
    from_igw_to_vpc          = optional(string)
    from_igw_to_subnet_group = optional(string)
    delay                    = optional(number, 0)
    tags                     = optional(map(string))
    cloudngfw_key            = optional(string)
  }))
}
