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
    })))
    subnets = map(object({
      name                    = optional(string)
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
    }))
    routes = map(object({
      vpc                    = string
      subnet_group           = string
      to_cidr                = string
      next_hop_key           = string
      next_hop_type          = string
      destination_type       = optional(string, "ipv4")
      managed_prefix_list_id = optional(string)
    }))
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
      name   = "security-gwlb"
      vpc    = "security_vpc"
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
    tg_name      = optional(string)
    target_instances = optional(map(object({
      id = string
    })), {})
    acceptance_required           = optional(bool, false)
    allowed_principals            = optional(list(string), [])
    deregistration_delay          = optional(number)
    health_check_enabled          = optional(bool)
    health_check_interval         = optional(number, 5)
    health_check_matcher          = optional(string)
    health_check_path             = optional(string)
    health_check_port             = optional(number, 80)
    health_check_protocol         = optional(string)
    health_check_timeout          = optional(number)
    healthy_threshold             = optional(number, 3)
    unhealthy_threshold           = optional(number, 3)
    stickiness_type               = optional(string)
    rebalance_flows               = optional(string, "no_rebalance")
    lb_tags                       = optional(map(string), {})
    lb_target_group_tags          = optional(map(string), {})
    endpoint_service_tags         = optional(map(string), {})
    enable_lb_deletion_protection = optional(bool)
  }))
}

variable "gwlb_endpoints" {
  description = <<-EOF
  A map defining GWLB endpoints.

  Following properties are available:
  - `name`: name of the GWLB endpoint
  - `custom_names`: Optional map of names of the VPC Endpoints, used to override the default naming generated from the input `name`. 
    Each key is the Availability Zone identifier, for example `us-east-1b.
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
  default = {
    security_vpc   = "security_vpc"
    peering_vpc_id = null
    vpc_cidr       = "10.255.0.0/24"
  }
  type = object({
    security_vpc   = string
    peering_vpc_id = string
    vpc_cidr       = string
  })
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
    }
  }
  ```
  EOF
  default     = {}
  type = map(object({
    bootstrap_options = object({
      hostname                              = optional(string)
      mgmt-interface-swap                   = string
      plugin-op-commands                    = string
      op-command-modes                      = optional(string)
      panorama-server                       = string
      panorama-server-2                     = optional(string)
      auth-key                              = optional(string)
      vm-auth-key                           = optional(string)
      dgname                                = string
      tplname                               = optional(string)
      cgname                                = optional(string)
      dns-primary                           = optional(string)
      dns-secondary                         = optional(string)
      dhcp-send-hostname                    = optional(string)
      dhcp-send-client-id                   = optional(string)
      dhcp-accept-server-hostname           = optional(string)
      dhcp-accept-server-domain             = optional(string)
      authcodes                             = optional(string)
      vm-series-auto-registration-pin-id    = optional(string)
      vm-series-auto-registration-pin-value = optional(string)
    })

    panos_version                          = string
    vmseries_ami_id                        = optional(string)
    vmseries_product_code                  = optional(string, "6njl1pau431dv1qxipg63mvah")
    include_deprecated_ami                 = optional(bool, false)
    instance_type                          = optional(string, "m5.xlarge")
    ebs_encrypted                          = optional(bool, true)
    ebs_kms_id                             = optional(string, "alias/aws/ebs")
    enable_instance_termination_protection = optional(bool, false)
    enable_monitoring                      = optional(bool, false)
    fw_license_type                        = optional(string, "byol")


    vpc  = string
    gwlb = optional(string)

    zones = map(any)

    interfaces = map(object({
      device_index      = number
      security_group    = string
      subnet_group      = string
      create_public_ip  = optional(bool, false)
      source_dest_check = bool
    }))

    subinterfaces = map(map(object({
      gwlb_endpoint = string
      subinterface  = string
    })))

    lambda_timeout                 = optional(number, 30)
    delicense_ssm_param_name       = optional(string)
    delicense_enabled              = optional(bool, false)
    reserved_concurrent_executions = optional(number, 100)
    asg_name                       = optional(string, "asg")
    asg = object({
      desired_cap                     = optional(number, 2)
      min_size                        = optional(number, 1)
      max_size                        = optional(number, 2)
      lambda_execute_pip_install_once = optional(bool, false)
      lifecycle_hook_timeout          = optional(number, 300)
      health_check = optional(object({
        grace_period = number
        type         = string
        }), {
        grace_period = 300
        type         = "EC2"
      })
      delete_timeout      = optional(string, "20m")
      suspended_processes = optional(list(string), [])
    })

    scaling_plan = object({
      enabled                   = optional(bool, false)
      metric_name               = optional(string, "")
      estimated_instance_warmup = optional(number, 900)
      target_value              = optional(number, 70)
      statistic                 = optional(string, "Average")
      cloudwatch_namespace      = optional(string, "VMseries_dimensions")
      tags                      = map(string)
    })

    launch_template_update_default_version = optional(bool, true)
    launch_template_version                = optional(string, "$Latest")
    tag_specifications_targets             = optional(list(string), ["instance", "volume", "network-interface"])

    instance_refresh = optional(object({
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
    }), null)

    application_lb = optional(object({
      name           = optional(string)
      subnet_group   = optional(string)
      security_group = optional(string)
      rules          = optional(any)
    }), {})

    network_lb = optional(object({
      name         = optional(string)
      subnet_group = optional(string)
      rules        = optional(any)
    }), {})
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
      type           = "t3.micro"
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
