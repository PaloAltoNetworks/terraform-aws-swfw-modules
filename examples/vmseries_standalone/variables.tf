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
  - `assign_generated_ipv6_cidr_block`: A boolean flag to assign AWS-provided /56 IPv6 CIDR block.
  - `nacls`: map of network ACLs
  - `security_groups`: map of security groups
  - `subnets`: map of subnets with properties:
     - `az`: availability zone
     - `subnet_group` - key of the subnet group
     - `nacl`: key of NACL (can be null)
     - `ipv6_index` - choose index for auto-generated IPv6 CIDR, must be null while used with IPv4 only
  - `routes`: map of routes with properties:
     - `vpc` - key of VPC
     - `subnet_group` - key of the subnet group
     - `to_cidr` - CIDR for route
     - `next_hop_key` - must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
     - `next_hop_type` - internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
     - `destination_type` - provide destination type. Available options `ipv4`, `ipv6`, `mpl`

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
      }
      routes = {
        vm_default = {
          vpc              = "app1_vpc"
          subnet_group     = "app1_vm"
          to_cidr          = "0.0.0.0/0"
          destination_type = "ipv4"
          next_hop_key     = "app1"
          next_hop_type    = "transit_gateway_attachment"
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    name                             = string
    cidr                             = string
    assign_generated_ipv6_cidr_block = bool
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
        description      = string
        type             = string
        from_port        = string
        to_port          = string
        protocol         = string
        cidr_blocks      = optional(list(string))
        ipv6_cidr_blocks = optional(list(string))
      }))
    }))
    subnets = map(object({
      az                      = string
      subnet_group            = string
      nacl                    = optional(string)
      create_subnet           = optional(bool, true)
      create_route_table      = optional(bool, true)
      existing_route_table_id = optional(string)
      associate_route_table   = optional(bool, true)
      route_table_name        = optional(string)
      ipv6_index              = number
      local_tags              = optional(map(string), {})
    }))
    routes = map(object({
      vpc              = string
      subnet_group     = string
      to_cidr          = string
      destination_type = string
      next_hop_key     = string
      next_hop_type    = string
    }))
  }))
}

### VM-SERIES
variable "vmseries" {
  description = <<-EOF
  A map defining VM-Series instances
  Following properties are available:
  - `instances`: map of VM-Series instances
  - `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama
  - `panos_version`: PAN-OS version used for VM-Series
  - `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series
  - `vpc`: key of VPC
  Example:
  ```
  vmseries = {
    vmseries = {
      instances = {
        "01" = { az = "eu-central-1a" }
      }
      # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`
      bootstrap_options = {
        mgmt-interface-swap         = "enable"
        plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable"
        dhcp-send-hostname          = "yes"
        dhcp-send-client-id         = "yes"
        dhcp-accept-server-hostname = "yes"
        dhcp-accept-server-domain   = "yes"
      }
      panos_version = "10.2.3"        # TODO: update here
      ebs_kms_id    = "alias/aws/ebs" # TODO: update here

      # Value of `vpc` must match key of objects stored in `vpcs`
      vpc = "security_vpc"

      interfaces = {
        mgmt = {
          device_index      = 1
          private_ip        = "10.100.0.4"
          security_group    = "vmseries_mgmt"
          vpc               = "security_vpc"
          subnet_group      = "mgmt"
          create_public_ip  = true
          source_dest_check = true
          eip_allocation_id = null
        }
      }
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    instances = map(object({
      az = string
    }))

    bootstrap_options = object({
      mgmt-interface-swap                   = string
      panorama-server                       = string
      tplname                               = optional(string)
      dgname                                = string
      plugin-op-commands                    = string
      dhcp-send-hostname                    = string
      dhcp-send-client-id                   = string
      dhcp-accept-server-hostname           = string
      dhcp-accept-server-domain             = string
      vm-series-auto-registration-pin-id    = optional(string)
      vm-series-auto-registration-pin-value = optional(string)
    })

    panos_version = string
    ebs_kms_id    = string

    vpc = string

    interfaces = map(object({
      device_index       = number
      security_group     = string
      vpc                = string
      subnet_group       = string
      create_public_ip   = bool
      private_ip         = map(string)
      ipv6_address_count = number
      source_dest_check  = bool
      eip_allocation_id  = map(string)
    }))
  }))
}
