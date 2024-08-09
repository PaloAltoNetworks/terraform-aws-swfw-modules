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
  security_vpc = {
    name = "security_vpc"
    cidr_block = {
      ipv4 = "10.100.0.0/16"
    }
    subnets = {
      # Value of `nacl` must match key of objects stored in `nacls`
      tgw_attacha   = { az = "a", cidr_block = "10.100.0.0/24", subnet_group = "tgw_attach", name = "tgw_attach1" }
      tgw_attachb   = { az = "b", cidr_block = "10.100.64.0/24", subnet_group = "tgw_attach", name = "tgw_attach2" }
      cngfw_subneta = { az = "a", cidr_block = "10.100.1.0/24", subnet_group = "cngfw_subnet", name = "cngfw_subnet1" }
      cngfw_subnetb = { az = "b", cidr_block = "10.100.65.0/24", subnet_group = "cngfw_subnet", name = "cngfw_subnet2" }
      natgwa        = { az = "a", cidr_block = "10.100.2.0/24", subnet_group = "natgw", name = "natgw1" }
      natgwb        = { az = "b", cidr_block = "10.100.66.0/24", subnet_group = "natgw", name = "natgw2" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      tgw_default = {
        vpc           = "security_vpc"
        subnet_group  = "tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_endpoint"
        next_hop_type = "gwlbe_endpoint"
      }
      eastwest_rfc1918 = {
        vpc           = "security_vpc"
        subnet_group  = "cngfw_subnet"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      cngfw_default = {
        vpc           = "security_vpc"
        subnet_group  = "cngfw_subnet"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_nat_gw"
        next_hop_type = "nat_gateway"
      }
      nat_default = {
        vpc           = "security_vpc"
        subnet_group  = "natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
      nat_app = {
        vpc           = "security_vpc"
        subnet_group  = "natgw"
        to_cidr       = "10.104.0.0/23"
        next_hop_key  = "cngfw_endpoint"
        next_hop_type = "gwlbe_endpoint"
      }
    }
    nacls           = {}
    security_groups = {}
  }
  app1_vpc = {
    name = "app1-spoke-vpc"
    cidr_block = {
      ipv4 = "10.104.0.0/16"
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      app1_vma    = { az = "a", cidr_block = "10.104.0.0/24", subnet_group = "app1_vm", name = "app1_vm1" }
      app1_vmb    = { az = "b", cidr_block = "10.104.128.0/24", subnet_group = "app1_vm", name = "app1_vm2" }
      app1_lba    = { az = "a", cidr_block = "10.104.2.0/24", subnet_group = "app1_lb", name = "app1_lb1" }
      app1_lbb    = { az = "b", cidr_block = "10.104.130.0/24", subnet_group = "app1_lb", name = "app1_lb2" }
      app1_gwlbea = { az = "a", cidr_block = "10.104.3.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe1" }
      app1_gwlbeb = { az = "b", cidr_block = "10.104.131.0/24", subnet_group = "app1_gwlbe", name = "app1_gwlbe2" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
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
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      app2_vma    = { az = "a", cidr_block = "10.105.0.0/24", subnet_group = "app2_vm", name = "app2_vm1" }
      app2_vmb    = { az = "b", cidr_block = "10.105.128.0/24", subnet_group = "app2_vm", name = "app2_vm2" }
      app2_lba    = { az = "a", cidr_block = "10.105.2.0/24", subnet_group = "app2_lb", name = "app2_lb1" }
      app2_lbb    = { az = "b", cidr_block = "10.105.130.0/24", subnet_group = "app2_lb", name = "app2_lb2" }
      app2_gwlbea = { az = "a", cidr_block = "10.105.3.0/24", subnet_group = "app2_gwlbe", name = "app2_gwlbe1" }
      app2_gwlbeb = { az = "b", cidr_block = "10.105.131.0/24", subnet_group = "app2_gwlbe", name = "app2_gwlbe2" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2"
        next_hop_type = "transit_gateway_attachment"
      }
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

### TRANSIT GATEWAY
tgw = {
  create = true
  id     = null
  name   = "tgw"
  asn    = "64512"
  route_tables = {
    # Do not change keys `from_security_vpc` and `from_spoke_vpc` as they are used in `main.tf` and attachments
    "from_security_vpc" = {
      create = true
      name   = "from_security"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "from_spokes"
    }
  }
  attachments = {
    # Value of `route_table` and `propagate_routes_to` must match `route_tables` stores under `tgw`
    security = {
      name                = "cloudngfw"
      vpc                 = "security_vpc"
      subnet_group        = "tgw_attach"
      route_table         = "from_security_vpc"
      propagate_routes_to = "from_spoke_vpc"
    }
    app1 = {
      name                = "app1-spoke-vpc"
      vpc                 = "app1_vpc"
      subnet_group        = "app1_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc"
    }
    app2 = {
      name                = "app2-spoke-vpc"
      vpc                 = "app2_vpc"
      subnet_group        = "app2_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc"
    }
  }
}

### NAT GATEWAY
natgws = {
  security_nat_gw = {
    name         = "natgw"
    vpc          = "security_vpc"
    subnet_group = "natgw"
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
      #rule_2 = {
      #  rule_list                   = "LocalRule"
      #  priority                    = 1
      #  name                        = "eastwest"
      #  description                 = "East West test rule"
      #  source_cidrs                = ["any"]
      #  destination_cidrs           = ["10.104.0.0/23"]
      #  negate_destination          = false
      #  protocol                    = "application-default"
      #  applications                = ["any"]
      #  category_feeds              = null
      #  category_url_category_names = null
      #  action                      = "DenySilent"
      #  logging                     = true
      #  audit_comment               = "initial config"
      #}
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
  cngfw_endpoint = {
    name            = "cngfw_endpoint"
    vpc             = "security_vpc"
    subnet_group    = "cngfw_subnet"
    act_as_next_hop = false
    delay           = 60
    cloudngfw       = "cloudngfws_security"
  }
  app1_inbound = {
    name               = "app1-gwlb-endpoint"
    vpc                = "app1_vpc"
    subnet_group       = "app1_gwlbe"
    act_as_next_hop    = true
    from_igw_to_vpc    = "app1_vpc"
    from_igw_to_subnet = "app1_lb"
    delay              = 120
    cloudngfw          = "cloudngfws_security"
  }
  app2_inbound = {
    name               = "app2-gwlb-endpoint"
    vpc                = "app2_vpc"
    subnet_group       = "app2_gwlbe"
    act_as_next_hop    = true
    from_igw_to_vpc    = "app2_vpc"
    from_igw_to_subnet = "app2_lb"
    delay              = 120
    cloudngfw          = "cloudngfws_security"
  }
}

### SPOKE VMS
spoke_vms = {
  "app1_vm01" = {
    az             = "a"
    vpc            = "app1_vpc"
    subnet_group   = "app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app1_vm02" = {
    az             = "b"
    vpc            = "app1_vpc"
    subnet_group   = "app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app2_vm01" = {
    az             = "a"
    vpc            = "app2_vpc"
    subnet_group   = "app2_vm"
    security_group = "app2_vm"
    type           = "t2.micro"
  }
  "app2_vm02" = {
    az             = "b"
    vpc            = "app2_vpc"
    subnet_group   = "app2_vm"
    security_group = "app2_vm"
    type           = "t2.micro"
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