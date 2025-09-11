### GENERAL
variable "region" {
  description = "AWS region used to deploy whole infrastructure"
  type        = string
}
variable "name_prefix" {
  description = "Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.)"
  default     = ""
  type        = string
}
variable "global_tags" {
  description = "Global tags configured for all provisioned resources"
  default     = {}
  type        = map(any)
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

### PANORAMA
variable "panoramas" {
  description = <<-EOF
  A map defining Panorama instances

  Following properties are available:
  - `instances`: map of Panorama instances with attributes:
    - `az`: name of the Availability Zone
    - `private_ip_address`: private IP address for management interface
  - `panos_version`: PAN-OS version used for Panorama
  - `network`: definition of network settings in object with attributes:
    - `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)
    - `subnet_group` - key of the subnet group
    - `security_group`: security group assigned to ENI used by Panorama
    - `create_public_ip`: true, if public IP address for management should be created
  - `ebs`: EBS settings defined in object with attributes:
    - `volumes`: list of EBS volumes attached to each instance
    - `kms_key_alias`: KMS key alias used for encrypting Panorama EBS
  - `iam`: IAM settings in object with attrbiutes:
    - `create_role`: enable creation of IAM role
    - `role_name`: name of the role to create or use existing one
  - `enable_imdsv2`: whether to enable IMDSv2 on the EC2 instance

  Example:
  ```
  {
    panorama_ha_pair = {
      instances = {
        "primary" = {
          az                 = "eu-central-1a"
          private_ip_address = "10.255.0.4"
        }
        "secondary" = {
          az                 = "eu-central-1b"
          private_ip_address = "10.255.1.4"
        }
      }

      panos_version = "10.2.3"

      network = {
        vpc              = "management_vpc"
        subnet_group     = "mgmt"
        security_group   = "panorama_mgmt"
        create_public_ip = true
      }

      ebs = {
        volumes = [
          {
            name            = "ebs-1"
            ebs_device_name = "/dev/sdb"
            ebs_size        = "2000"
            ebs_encrypted   = true
          },
          {
            name            = "ebs-2"
            ebs_device_name = "/dev/sdc"
            ebs_size        = "2000"
            ebs_encrypted   = true
          }
        ]
        kms_key_alias = "aws/ebs"
      }

      iam = {
        create_role = true
        role_name   = "panorama"
      }

      enable_imdsv2 = false
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    instances = map(object({
      name               = optional(string)
      az                 = string
      private_ip_address = string
    }))

    panos_version = string

    network = object({
      vpc              = string
      subnet_group     = string
      security_group   = string
      create_public_ip = bool
    })

    ebs = object({
      volumes = list(object({
        name            = string
        ebs_device_name = string
        ebs_size        = string
        force_detach    = optional(bool, false)
        skip_destroy    = optional(bool, false)
      }))
      encrypted     = bool
      kms_key_alias = optional(string, "alias/aws/ebs")
    })

    product_code           = optional(string, "eclz7j04vu9lf8ont8ta3n17o")
    include_deprecated_ami = optional(bool, false)
    panorama_ami_id        = optional(string)
    instance_type          = optional(string, "c5.4xlarge")
    enable_monitoring      = optional(bool, false)
    eip_domain             = optional(string, "vpc")

    iam = object({
      create_role = bool
      role_name   = string
    })

    enable_imdsv2 = optional(bool, false)
  }))
}
