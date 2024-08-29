### Provider
provider_account = ""
provider_role    = "cloudngfw"

### GENERAL
region      = "eu-west-1"  # TODO: update here
name_prefix = "cloudngfw-" # TODO: update here

tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-ssh-key" # TODO: update here

### VPC
vpcs = {
  app1_vpc = {
    name = "app1-spoke-vpc"
    cidr_block = {
      ipv4 = "10.104.0.0/16"
    }
    subnets = {
      app1_vma     = { az = "a", cidr_block = "10.104.0.0/24", subnet_group = "app1_vm", name = "app1_vm1" }
      app1_vmb     = { az = "b", cidr_block = "10.104.128.0/24", subnet_group = "app1_vm", name = "app1_vm2" }
      app1_lba     = { az = "a", cidr_block = "10.104.2.0/24", subnet_group = "app1_lb", name = "app1_lb1" }
      app1_lbb     = { az = "b", cidr_block = "10.104.130.0/24", subnet_group = "app1_lb", name = "app1_lb2" }
      app1_gwlbea  = { az = "a", cidr_block = "10.104.3.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe11" }
      app1_gwlbeb  = { az = "b", cidr_block = "10.104.131.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe12" }
      app1_natgwa  = { az = "a", cidr_block = "10.104.4.0/24", subnet_group = "app1_natgw", name = "app1_natgw1" }
      app1_natgwb  = { az = "b", cidr_block = "10.104.132.0/24", subnet_group = "app1_natgw", name = "app1_natgw2" }
      app1_gwlbe2a = { az = "a", cidr_block = "10.104.5.0/24", subnet_group = "app1_gwlbe2", name = "app1_gwlbe21" }
      app1_gwlbe2b = { az = "b", cidr_block = "10.104.133.0/24", subnet_group = "app1_gwlbe2", name = "app1_gwlbe22" }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
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
      nat_default = {
        vpc           = "app1_vpc"
        subnet_group  = "app1_natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_vpc"
        next_hop_type = "internet_gateway"
      }
      nat_app_az1 = {
        vpc           = "app1_vpc"
        subnet_group  = "app1_natgw"
        to_cidr       = "10.104.0.0/24"
        next_hop_key  = "app1_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_app_az2 = {
        vpc           = "app1_vpc"
        subnet_group  = "app1_natgw"
        to_cidr       = "10.104.128.0/24"
        next_hop_key  = "app1_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      app_default = {
        vpc           = "app1_vpc"
        subnet_group  = "app1_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      gwlbe1_default = {
        vpc           = "app1_vpc"
        subnet_group  = "app1_gwlbe2"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_nat_gw"
        next_hop_type = "nat_gateway"
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
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
      app1_lb = {
        name = "app1_lb"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
  }
  app2_vpc = {
    name = "app2-spoke-vpc"
    cidr_block = {
      ipv4 = "10.105.0.0/16"
    }
    subnets = {
      app2_vma     = { az = "a", cidr_block = "10.105.0.0/24", subnet_group = "app2_vm", name = "app2_vm1" }
      app2_vmb     = { az = "b", cidr_block = "10.105.128.0/24", subnet_group = "app2_vm", name = "app2_vm2" }
      app2_lba     = { az = "a", cidr_block = "10.105.2.0/24", subnet_group = "app2_lb", name = "app2_lb1" }
      app2_lbb     = { az = "b", cidr_block = "10.105.130.0/24", subnet_group = "app2_lb", name = "app2_lb2" }
      app2_gwlbea  = { az = "a", cidr_block = "10.105.3.0/24", subnet_group = "app2_gwlbe", name = "app2_gwlbe11" }
      app2_gwlbeb  = { az = "b", cidr_block = "10.105.131.0/24", subnet_group = "app2_gwlbe", name = "app2_gwlbe12" }
      app2_natgwa  = { az = "a", cidr_block = "10.105.4.0/24", subnet_group = "app2_natgw", name = "app2_natgw1" }
      app2_natgwb  = { az = "b", cidr_block = "10.105.132.0/24", subnet_group = "app2_natgw", name = "app2_natgw2" }
      app2_gwlbe2a = { az = "a", cidr_block = "10.105.5.0/24", subnet_group = "app2_gwlbe2", name = "app2_gwlbe21" }
      app2_gwlbe2b = { az = "b", cidr_block = "10.105.133.0/24", subnet_group = "app2_gwlbe2", name = "app2_gwlbe22" }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      gwlbe_default = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_gwlbe"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_vpc"
        next_hop_type = "internet_gateway"
      }
      lb_default = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_lb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_inbound"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_default = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_vpc"
        next_hop_type = "internet_gateway"
      }
      nat_app_az1 = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_natgw"
        to_cidr       = "10.105.0.0/24"
        next_hop_key  = "app2_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_app_az2 = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_natgw"
        to_cidr       = "10.105.128.0/24"
        next_hop_key  = "app2_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      app_default = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      gwlbe2_default = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_gwlbe2"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_nat_gw"
        next_hop_type = "nat_gateway"
      }
    }
    nacls = {}
    security_groups = {
      app2_vm = {
        name = "app2_vm"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
      app2_lb = {
        name = "app2_lb"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
  }
}

### NAT GATEWAY
natgws = {
  app1_nat_gw = {
    name         = "natgw"
    vpc          = "app1_vpc"
    subnet_group = "app1_natgw"
  }
  app2_nat_gw = {
    name         = "natgw"
    vpc          = "app2_vpc"
    subnet_group = "app2_natgw"
  }
}

### Cloud NGFW
cloudngfws = {
  cloudngfws_security = {
    name         = "cloudngfw01"
    vpc          = "app1_vpc"
    subnet_group = "app1_gwlbe"
    description  = "Description"
    security_rules = {
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
        create_cw        = false
        name             = "PaloAltoCloudNGFW"
        destination_type = "CloudWatchLogs"
        log_type         = "THREAT"
      }
      dest_2 = {
        create_cw        = false
        name             = "PaloAltoCloudNGFW"
        destination_type = "CloudWatchLogs"
        log_type         = "TRAFFIC"
      }
      dest_3 = {
        create_cw        = false
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

gwlb_endpoints = {
  # Value of `gwlb` must match key of objects stored in `gwlbs`
  # Value of `vpc` must match key of objects stored in `vpcs`
  # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
  app1_inbound = {
    name            = "app1-gwlb-endpoint"
    vpc             = "app1_vpc"
    subnet_group    = "app1_gwlbe"
    act_as_next_hop = true
    to_vpc          = "app1_vpc"
    to_subnet_group = "app1_lb"
    delay           = 60
    cloudngfw       = "cloudngfws_security"
  }
  app1_outbound = {
    name            = "app1-gwlb-out-endpoint"
    vpc             = "app1_vpc"
    subnet_group    = "app1_gwlbe2"
    act_as_next_hop = false
    to_vpc          = null
    to_subnet_group = null
    delay           = 60
    cloudngfw       = "cloudngfws_security"
  }
  app2_inbound = {
    name            = "app2-gwlb-endpoint"
    vpc             = "app2_vpc"
    subnet_group    = "app2_gwlbe"
    act_as_next_hop = true
    to_vpc          = "app2_vpc"
    to_subnet_group = "app2_lb"
    delay           = 60
    cloudngfw       = "cloudngfws_security"
  }
  app2_outbound = {
    name            = "app2-gwlb-out-endpoint"
    vpc             = "app2_vpc"
    subnet_group    = "app2_gwlbe2"
    act_as_next_hop = false
    to_vpc          = null
    to_subnet_group = null
    delay           = 60
    cloudngfw       = "cloudngfws_security"
  }
}

### SPOKE VMS
spoke_vms = {
  "app1_vm01" = {
    az             = "a"
    vpc            = "app1_vpc"
    subnet_group   = "app1_vm"
    security_group = "app1_vm"
    type           = "t3.micro"
  }
  "app1_vm02" = {
    az             = "b"
    vpc            = "app1_vpc"
    subnet_group   = "app1_vm"
    security_group = "app1_vm"
    type           = "t3.micro"
  }
  "app2_vm01" = {
    az             = "a"
    vpc            = "app2_vpc"
    subnet_group   = "app2_vm"
    security_group = "app2_vm"
    type           = "t3.micro"
  }
  "app2_vm02" = {
    az             = "b"
    vpc            = "app2_vpc"
    subnet_group   = "app2_vm"
    security_group = "app2_vm"
    type           = "t3.micro"
  }
}

### SPOKE LOADBALANCERS
spoke_nlbs = {
  "app1-nlb" = {
    vpc          = "app1_vpc"
    subnet_group = "app1_lb"
    vms          = ["app1_vm01", "app1_vm02"]
  }
  "app2-nlb" = {
    vpc          = "app2_vpc"
    subnet_group = "app2_lb"
    vms          = ["app2_vm01", "app2_vm02"]
  }
}

spoke_albs = {
  "app1-alb" = {
    vms = ["app1_vm01", "app1_vm02"]
    rules = {
      "app1" = {
        protocol              = "HTTP"
        port                  = 80
        health_check_port     = "80"
        health_check_matcher  = "200"
        health_check_path     = "/"
        health_check_interval = 10
        listener_rules = {
          "1" = {
            target_protocol = "HTTP"
            target_port     = 80
            path_pattern    = ["/"]
          }
        }
      }
    }
    vpc             = "app1_vpc"
    subnet_group    = "app1_lb"
    security_groups = "app1_lb"
  }
  "app2-alb" = {
    vms = ["app2_vm01", "app2_vm02"]
    rules = {
      "app2" = {
        protocol              = "HTTP"
        port                  = 80
        health_check_port     = "80"
        health_check_matcher  = "200"
        health_check_path     = "/"
        health_check_interval = 10
        listener_rules = {
          "1" = {
            target_protocol = "HTTP"
            target_port     = 80
            path_pattern    = ["/"]
          }
        }
      }
    }
    vpc             = "app2_vpc"
    subnet_group    = "app2_lb"
    security_groups = "app2_lb"
  }
}
