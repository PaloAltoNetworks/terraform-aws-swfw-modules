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
  - `security_groups`: map of security groups
  - `subnets`: map of subnets with properties:
     - `az`: availability zone
     - `subnet_group`: identity of the same purpose subnets group such as management
  - `routes`: map of routes with properties:
     - `vpc - key of the VPC
     - `subnet_group` - key of the subnet group
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
        "10.104.0.0/24"   = { az = "eu-central-1a", subnet_group = "vm", nacl = null }
        "10.104.128.0/24" = { az = "eu-central-1b", subnet_group = "vm", nacl = null }
      }
      routes = {
        vm_default = {
          vpc           = "app1_vpc"
          subnet_group  = "app1_vm"
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
      az           = string
      subnet_group = string
      nacl         = string
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

### TRANSIT GATEWAY
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
      subnet_group        = string
      route_table         = string
      propagate_routes_to = list(string)
    }))
  })
}

### NAT GATEWAY
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
  - `subnet_group`: key of the subnet_group
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

### VM-SERIES
variable "vmseries_asgs" {
  description = <<-EOF
  A map defining Autoscaling Groups with VM-Series instances.

  Following properties are available:
  - `bootstrap_options`: VM-Seriess bootstrap options used to connect to Panorama
  - `panos_version`: PAN-OS version used for VM-Series
  - `ebs_kms_id`: alias for AWS KMS used for EBS encryption in VM-Series
  - `vpc`: key of VPC
  - `gwlb`: key of GWLB
  - `zones`: zones for the Autoscaling Group to be built in
  - `interfaces`: configuration of network interfaces for VM-Series used by Lamdba while provisioning new VM-Series in autoscaling group
  - `subinterfaces`: configuration of network subinterfaces used to map with GWLB endpoints
  - `asg`: the number of Amazon EC2 instances that should be running in the group (desired, minimum, maximum)
  - `scaling_plan`: scaling plan with attributes
    - `enabled`: `true` if automatic dynamic scaling policy should be created
    - `metric_name`: name of the metric used in dynamic scaling policy
    - `estimated_instance_warmup`: estimated time, in seconds, until a newly launched instance can contribute to the CloudWatch metrics
    - `target_value`: target value for the metric used in dynamic scaling policy
    - `statistic`: statistic of the metric. Valid values: Average, Maximum, Minimum, SampleCount, Sum
    - `cloudwatch_namespace`: name of CloudWatch namespace, where metrics are available (it should be the same as namespace configured in VM-Series plugin in PAN-OS)
    - `tags`: tags configured for dynamic scaling policy
  - `launch_template_version`: launch template version to use to launch instances
  - `instance_refresh`: instance refresh for ASG defined by several attributes (please see README for module `asg` for more details)

  Example:
  ```
  vmseries_asgs = {
    main_asg = {
      bootstrap_options = {
        mgmt-interface-swap         = "enable"
        plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable" # TODO: update here
        panorama-server             = ""                                                                                   # TODO: update here
        auth-key                    = ""                                                                                   # TODO: update here
        dgname                      = ""                                                                                   # TODO: update here
        tplname                     = ""                                                                                   # TODO: update here
        dhcp-send-hostname          = "yes"                                                                                # TODO: update here
        dhcp-send-client-id         = "yes"                                                                                # TODO: update here
        dhcp-accept-server-hostname = "yes"                                                                                # TODO: update here
        dhcp-accept-server-domain   = "yes"                                                                                # TODO: update here
      }

      panos_version = "10.2.3"        # TODO: update here
      ebs_kms_id    = "alias/aws/ebs" # TODO: update here

      vpc               = "security_vpc"
      gwlb              = "security_gwlb"

      zones = {
        "01" = "us-west-1a"
        "02" = "us-west-1b"
      }

      interfaces = {
        private = {
          device_index   = 0
          security_group = "vmseries_private"
          subnet_group = "private"
          create_public_ip  = false
          source_dest_check = false
        }
        mgmt = {
          device_index   = 1
          security_group = "vmseries_mgmt"
          subnet_group = "mgmt"
          create_public_ip  = true
          source_dest_check = true
        }
        public = {
          device_index   = 2
          security_group = "vmseries_public"
          subnet_group = "public"
          create_public_ip  = false
          source_dest_check = false
        }
      }

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

      asg = {
        desired_cap                     = 0
        min_size                        = 0
        max_size                        = 4
        lambda_execute_pip_install_once = true
      }

      scaling_plan = {
        enabled                   = true
        metric_name               = "panSessionActive"
        estimated_instance_warmup = 900
        target_value              = 75
        statistic                 = "Average"
        cloudwatch_namespace      = "asg-vmseries"
        tags = {
          ManagedBy = "terraform"
        }
      }

      launch_template_version = "1"

      instance_refresh = {
        strategy = "Rolling"
        preferences = {
          checkpoint_delay             = 3600
          checkpoint_percentages       = [50, 100]
          instance_warmup              = 1200
          min_healthy_percentage       = 50
          skip_matching                = false
          auto_rollback                = false
          scale_in_protected_instances = "Ignore"
          standby_instances            = "Ignore"
        }
        triggers = []
      }

      application_lb = null
      network_lb     = null      
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    bootstrap_options = object({
      mgmt-interface-swap                   = string
      plugin-op-commands                    = string
      panorama-server                       = string
      auth-key                              = optional(string)
      vm-auth-key                           = optional(string)
      dgname                                = string
      tplname                               = optional(string)
      dhcp-send-hostname                    = string
      dhcp-send-client-id                   = string
      dhcp-accept-server-hostname           = string
      dhcp-accept-server-domain             = string
      authcodes                             = optional(string)
      vm-series-auto-registration-pin-id    = optional(string)
      vm-series-auto-registration-pin-value = optional(string)
    })

    panos_version = string
    ebs_kms_id    = string

    vpc  = string
    gwlb = string

    zones = map(any)

    interfaces = map(object({
      device_index      = number
      security_group    = string
      subnet_group      = string
      create_public_ip  = bool
      source_dest_check = bool
    }))

    subinterfaces = map(map(object({
      gwlb_endpoint = string
      subinterface  = string
    })))

    asg = object({
      desired_cap                     = number
      min_size                        = number
      max_size                        = number
      lambda_execute_pip_install_once = bool
    })

    scaling_plan = object({
      enabled                   = bool
      metric_name               = string
      estimated_instance_warmup = number
      target_value              = number
      statistic                 = string
      cloudwatch_namespace      = string
      tags                      = map(string)
    })

    launch_template_version = string

    instance_refresh = object({
      strategy = string
      preferences = object({
        checkpoint_delay             = number
        checkpoint_percentages       = list(number)
        instance_warmup              = number
        min_healthy_percentage       = number
        skip_matching                = bool
        auto_rollback                = bool
        scale_in_protected_instances = string
        standby_instances            = string
      })
      triggers = list(string)
    })

    application_lb = object({
      name           = string
      subnet_group   = string
      security_group = string
      rules          = any
    })

    network_lb = object({
      name         = string
      subnet_group = string
      rules        = any
    })
  }))
}

### PANORAMA
variable "panorama_attachment" {
  description = <<-EOF
  A object defining TGW attachment and CIDR for Panorama.

  Following properties are available:
  - `transit_gateway_attachment_id`: ID of attachment for Panorama
  - `vpc_cidr`: CIDR of the VPC, where Panorama is deployed

  Example:
  ```
  panorama = {
    transit_gateway_attachment_id = "tgw-attach-123456789"
    vpc_cidr                      = "10.255.0.0/24"
  }
  ```
  EOF
  default     = null
  type = object({
    transit_gateway_attachment_id = string
    vpc_cidr                      = string
  })
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
    type           = string
  }))
}

### SPOKE LOADBALANCERS
variable "spoke_lbs" {
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
      vpc    = "app1_vpc"
      subnet_group = "app1_lb"
      vms    = ["app1_vm01", "app1_vm02"]
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
