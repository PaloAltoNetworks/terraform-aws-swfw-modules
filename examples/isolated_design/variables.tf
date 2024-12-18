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

### IAM
variable "iam_policies" {
  description = "A map defining an IAM policies, roles etc."
  default = {
    spoke = {
      create_instance_profile = true
      instance_profile_name   = "isolated_spoke_profile"
      role_name               = "spoke_role"
      policy_arn              = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
    vmseries = {
      create_instance_profile = true
      instance_profile_name   = "isolated_vmseries_profile"
      role_name               = "vmseries_role"
      create_vmseries_policy  = true
    }
  }
  type = map(object({
    role_name               = string
    create_role             = optional(bool, true)
    principal_role          = optional(string, "ec2.amazonaws.com")
    create_instance_profile = optional(bool, false)
    instance_profile_name   = optional(string)
    create_lambda_policy    = optional(bool, false)
    create_bootrap_policy   = optional(bool, false)
    policy_arn              = optional(string)
    create_vmseries_policy  = optional(bool, false)
    create_panorama_policy  = optional(bool, false)
    custom_policy = optional(map(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
      condition = optional(object({
        test     = string
        variable = string
        values   = list(string)
      }))
    })))
    delicense_ssm_param_name = optional(string)
    aws_s3_bucket            = optional(string)
  }))
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
      route_table   = string
      to_cidr       = string
      az            = string
      next_hop_type = string
      next_hop_key  = string
    }))
  }))
}

### GATEWAY LOADBALANCER
variable "gwlbs" {
  description = <<-EOF
  A map defining Gateway Load Balancers.

  Following properties are available:
  - `name`: name of the GWLB
  - `vpc`: key of the VPC
  - `subnet_group`: key of the subnet_group

  Example:
  ```
  gwlbs = {
    security_gwlb = {
      name         = "security-gwlb"
      vpc          = "security_vpc"
      subnet_group = "gwlb"
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

variable "gwlb_endpoints" {
  description = <<-EOF
  A map defining GWLB endpoints.

  Following properties are available:
  - `name`: name of the GWLB endpoint
  - `gwlb`: key of GWLB
  - `vpc`: key of VPC
  - `subnet_group`: key of subnet_group
  - `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic
  - `from_igw_to_vpc`: VPC to which traffic from IGW is routed to the GWLB endpoint
  - `from_igw_to_subnet_group` : subnet_group to which traffic from IGW is routed to the GWLB endpoint

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
    gwlb                     = string
    vpc                      = string
    subnet_group             = string
    act_as_next_hop          = bool
    from_igw_to_vpc          = optional(string)
    from_igw_to_subnet_group = optional(string)
  }))
}

### PANORAMA
variable "panorama_connection" {
  description = <<-EOF
  A object defining VPC peering and CIDR for Panorama.

  Following properties are available:
  - `security_vpc`: key of the security VPC
  - `peering_vpc_id`: ID of the VPC for Panorama
  - `vpc_cidr`: CIDR of the VPC, where Panorama is deployed

  Example:
  ```
  panorama = {
    security_vpc   = "security_vpc"
    peering_vpc_id = "vpc-1234567890"
    vpc_cidr       = "10.255.0.0/24"
  }
  ```
  EOF
  default     = null
  type = object({
    security_vpc   = string
    peering_vpc_id = string
    vpc_cidr       = string
  })
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
  - `gwlb`: key of GWLB
  - `subinterfaces`: configuration of network subinterfaces used to map with GWLB endpoints
  - `system_services`: map of system services
  - `application_lb`: ALB placed in front of the Firewalls' public interfaces
  - `network_lb`: NLB placed in front of the Firewalls' public interfaces
  Example:
  ```
  vmseries = {
    vmseries = {
      instances = {
        "01" = { az = "eu-central-1a" }
        "02" = { az = "eu-central-1b" }
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
      # Value of `gwlb` must match key of objects stored in `gwlbs`
      gwlb = "security_gwlb"
      interfaces = {
        private = {
          device_index      = 0
          security_group    = "vmseries_private"
          vpc               = "security_vpc"
          subnet_group      = "private"
          create_public_ip  = false
          source_dest_check = false
        }
        mgmt = {
          device_index      = 1
          security_group    = "vmseries_mgmt"
          vpc               = "security_vpc"
          subnet_group      = "mgmt"
          create_public_ip  = true
          source_dest_check = true
        }
        public = {
          device_index      = 2
          security_group    = "vmseries_public"
          vpc               = "security_vpc"
          subnet_group      = "public"
          create_public_ip  = true
          source_dest_check = false
        }
      }
      # Value of `gwlb_endpoint` must match key of objects stored in `gwlb_endpoints`
      subinterfaces = {
        inbound = {
          app1 = {
            gwlb_endpoint = "app1_inbound"
            subinterface  = "ethernet1/1.11"
          }
          app2 = {
            gwlb_endpoint = "app2_inbound"
            subinterface  = "ethernet1/1.12"
          }
        }
        outbound = {
          only_1_outbound = {
            gwlb_endpoint = "security_gwlb_outbound"
            subinterface  = "ethernet1/1.20"
          }
        }
        eastwest = {
          only_1_eastwest = {
            gwlb_endpoint = "security_gwlb_eastwest"
            subinterface  = "ethernet1/1.30"
          }
        }
      }
      system_services = {
        dns_primary = "4.2.2.2"      # TODO: update here
        dns_secondy = null           # TODO: update here
        ntp_primary = "pool.ntp.org" # TODO: update here
        ntp_secondy = null           # TODO: update here
      }
      application_lb = null
      network_lb     = null
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
      mgmt-interface-swap         = string
      plugin-op-commands          = string
      panorama-server             = string
      auth-key                    = string
      dgname                      = string
      tplname                     = string
      dhcp-send-hostname          = string
      dhcp-send-client-id         = string
      dhcp-accept-server-hostname = string
      dhcp-accept-server-domain   = string
    })

    panos_version = string
    ebs_kms_id    = string

    vpc  = string
    gwlb = string

    interfaces = map(object({
      device_index      = number
      security_group    = string
      vpc               = string
      subnet_group      = string
      create_public_ip  = bool
      source_dest_check = bool
    }))

    subinterfaces = map(map(object({
      gwlb_endpoint = string
      subinterface  = string
    })))

    system_services = object({
      dns_primary = string
      dns_secondy = string
      ntp_primary = string
      ntp_secondy = string
    })

    application_lb = object({
      name  = string
      rules = any
    })

    network_lb = object({
      name  = string
      rules = any
    })
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