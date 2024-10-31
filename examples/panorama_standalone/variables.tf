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
variable "tags" {
  description = "Tags configured for all provisioned resources"
  default     = {}
  type        = map(any)
}
variable "ssh_key_name" {
  description = "Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes"
  type        = string
}

### IAM
variable "iam_policies" {
  description = "A map defining an IAM policies, roles etc."
  type        = any

  default = {
    panorama = {
      create_instance_profile = true
      instance_profile_name   = "panorama_profile"
      role_name               = "panorama_role"
      create_panorama_policy  = true
    }
  }
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
      ipv6_index              = optional(number)
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
      route_table   = string
      to_cidr       = string
      az            = string
      next_hop_type = string
      next_hop_key  = string
    }))
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
      }))
      encrypted     = bool
      kms_key_alias = string
    })

    iam = object({
      create_role = bool
      role_name   = string
    })

    enable_imdsv2 = bool
  }))
}
