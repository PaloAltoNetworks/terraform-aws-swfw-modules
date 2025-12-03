### Provider
provider_account = ""
provider_role    = "cloudngfw"

### GENERAL
region      = "eu-west-1"  # TODO: update here
name_prefix = "cloudngfw-" # TODO: update here

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-ssh-key" # TODO: update here

### VPC
vpcs = {
  security_vpc_ew_ob = {
    name = "security_vpc_ew_ob"
    cidr = "10.100.0.0/16"
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf
      # Value of `nacl` must match key of objects stored in `nacls`
      "10.100.0.0/24"  = { az = "eu-west-1a", subnet_group = "tgw_attach" }
      "10.100.64.0/24" = { az = "eu-west-1b", subnet_group = "tgw_attach" }
      "10.100.1.0/24"  = { az = "eu-west-1a", subnet_group = "cngfw_subnet" }
      "10.100.65.0/24" = { az = "eu-west-1b", subnet_group = "cngfw_subnet" }
      "10.100.2.0/24"  = { az = "eu-west-1a", subnet_group = "natgw" }
      "10.100.66.0/24" = { az = "eu-west-1b", subnet_group = "natgw" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      tgw_default = {
        vpc           = "security_vpc_ew_ob"
        subnet_group  = "tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_endpoint"
        next_hop_type = "gwlbe_endpoint"
      }
      eastwest_rfc1918 = {
        vpc           = "security_vpc_ew_ob"
        subnet_group  = "cngfw_subnet"
        to_cidr       = "10.104.0.0/15"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      cngfw_default = {
        vpc           = "security_vpc_ew_ob"
        subnet_group  = "cngfw_subnet"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_nat_gw"
        next_hop_type = "nat_gateway"
      }
      nat_default = {
        vpc           = "security_vpc_ew_ob"
        subnet_group  = "natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc_ew_ob"
        next_hop_type = "internet_gateway"
      }
      nat_app = {
        vpc           = "security_vpc_ew_ob"
        subnet_group  = "natgw"
        to_cidr       = "10.104.0.0/15"
        next_hop_key  = "cngfw_endpoint"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
  security_vpc_ingress = {
    name  = "security_vpc_ingress"
    cidr  = "10.101.0.0/16"
    nacls = {}
    security_groups = {
      application_load_balancer = {
        name = "alb"
        rules = {
          http_inbound = {
            description = "Permit incoming HTTP traffic"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          https_inbound = {
            description = "Permit incoming HTTPS traffic"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf
      # Value of `nacl` must match key of objects stored in `nacls`
      "10.101.0.0/24"  = { az = "eu-west-1a", subnet_group = "tgw_attach" }
      "10.101.64.0/24" = { az = "eu-west-1b", subnet_group = "tgw_attach" }
      "10.101.1.0/24"  = { az = "eu-west-1a", subnet_group = "cngfw_subnet" }
      "10.101.65.0/24" = { az = "eu-west-1b", subnet_group = "cngfw_subnet" }
      "10.101.2.0/24"  = { az = "eu-west-1a", subnet_group = "alb" }
      "10.101.66.0/24" = { az = "eu-west-1b", subnet_group = "alb" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      tgw_default = {
        vpc           = "security_vpc_ingress"
        subnet_group  = "tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_endpoint_ingress"
        next_hop_type = "gwlbe_endpoint"
      }
      tgw_alb_a = {
        vpc           = "security_vpc_ingress"
        subnet_group  = "tgw_attach"
        to_cidr       = "10.101.2.0/24"
        next_hop_key  = "cngfw_endpoint_ingress"
        next_hop_type = "gwlbe_endpoint"
      }
      tgw_alb_b = {
        vpc           = "security_vpc_ingress"
        subnet_group  = "tgw_attach"
        to_cidr       = "10.101.66.0/24"
        next_hop_key  = "cngfw_endpoint_ingress"
        next_hop_type = "gwlbe_endpoint"
      }
      eastwest_rfc1918 = {
        vpc           = "security_vpc_ingress"
        subnet_group  = "cngfw_subnet"
        to_cidr       = "10.104.0.0/15"
        next_hop_key  = "security_ingress"
        next_hop_type = "transit_gateway_attachment"
      }
      alb_default = {
        vpc           = "security_vpc_ingress"
        subnet_group  = "alb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc_ingress"
        next_hop_type = "internet_gateway"
      }
      alb_app = {
        vpc           = "security_vpc_ingress"
        subnet_group  = "alb"
        to_cidr       = "10.104.0.0/15"
        next_hop_key  = "cngfw_endpoint_ingress"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
  app1_vpc = {
    name  = "app1-spoke-vpc"
    cidr  = "10.104.0.0/16"
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
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["10.101.2.0/24", "10.101.66.0/24", "10.104.0.0/15"]
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["10.101.2.0/24", "10.101.66.0/24", "10.104.0.0/15"]
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.104.0.0/24"   = { az = "eu-west-1a", subnet_group = "app1_vm" }
      "10.104.128.0/24" = { az = "eu-west-1b", subnet_group = "app1_vm" }
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
    }
  }
  app2_vpc = {
    name  = "app2-spoke-vpc"
    cidr  = "10.105.0.0/16"
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
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["10.101.2.0/24", "10.101.66.0/24", "10.104.0.0/15"]
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["10.101.2.0/24", "10.101.66.0/24", "10.104.0.0/15"]
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.105.0.0/24"   = { az = "eu-west-1a", subnet_group = "app2_vm" }
      "10.105.128.0/24" = { az = "eu-west-1b", subnet_group = "app2_vm" }
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
    }
  }
}

### TRANSIT GATEWAY
tgws = {
  tgw = {
    name = "tgw"
    asn  = "64512"
    route_tables = {
      # Do not change keys `from_security_vpc` and `from_spoke_vpc` as they are used in `main.tf` and attachments
      "from_security_vpc_ew_ob" = {
        create = true
        name   = "from_security_ew_ob"
      }
      "from_spoke_vpc" = {
        create = true
        name   = "from_spokes"
      }
      "from_security_ingress" = {
        create = true
        name   = "from_security_ingress"
      }
    }
  }
}

tgw_attachments = {
  # Value of `route_table` and `propagate_routes_to` must match `route_tables` stores under `tgw`
  security = {
    tgw_key                 = "tgw"
    security_vpc_attachment = true
    name                    = "cloudngfw"
    vpc                     = "security_vpc_ew_ob"
    subnet_group            = "tgw_attach"
    route_table             = "from_security_vpc_ew_ob"
    propagate_routes_to     = ["from_spoke_vpc"]
  }
  security_ingress = {
    tgw_key             = "tgw"
    name                = "cloudngfw_ingress"
    vpc                 = "security_vpc_ingress"
    subnet_group        = "tgw_attach"
    route_table         = "from_security_ingress"
    propagate_routes_to = ["from_spoke_vpc"]
  }
  app1 = {
    tgw_key             = "tgw"
    name                = "app1-spoke-vpc"
    vpc                 = "app1_vpc"
    subnet_group        = "app1_vm"
    route_table         = "from_spoke_vpc"
    propagate_routes_to = ["from_security_vpc_ew_ob"]
  }
  app2 = {
    tgw_key             = "tgw"
    name                = "app2-spoke-vpc"
    vpc                 = "app2_vpc"
    subnet_group        = "app2_vm"
    route_table         = "from_spoke_vpc"
    propagate_routes_to = ["from_security_vpc_ew_ob"]
  }
}


### NAT GATEWAY
natgws = {
  security_nat_gw = {
    vpc          = "security_vpc_ew_ob"
    subnet_group = "natgw"
  }
}

### Cloud NGFW
cloudngfws = {
  cloudngfws_security_ew_ob = {
    name         = "cloudngfw01"
    vpc          = "security_vpc_ew_ob"
    subnet_group = "cngfw_subnet"
    security_rules = {
      rule_1 = {
        rule_list                   = "LocalRule"
        priority                    = 3
        name                        = "tf-security-rule"
        description                 = "Configured by Terraform"
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
      #  destination_cidrs           = ["10.104.0.0/15"]
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

  cloudngfws_security_ingress = {
    name         = "cloudngfw02"
    vpc          = "security_vpc_ingress"
    subnet_group = "cngfw_subnet"
    security_rules = {
      rule_1 = {
        rule_list                   = "LocalRule"
        priority                    = 3
        name                        = "ingress-rule"
        description                 = "Configured by Terraform"
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
  cngfw_endpoint = {
    name            = "cngfw_endpoint"
    vpc             = "security_vpc_ew_ob"
    subnet_group    = "cngfw_subnet"
    act_as_next_hop = false
    delay           = 60
    cloudngfw_key   = "cloudngfws_security_ew_ob"
  }
  cngfw_endpoint_ingress = {
    name            = "cngfw_endpoint_ingress"
    vpc             = "security_vpc_ingress"
    subnet_group    = "cngfw_subnet"
    act_as_next_hop = false
    delay           = 60
    cloudngfw_key   = "cloudngfws_security_ingress"
  }
}

spoke_albs = {
  "app1-alb" = {
    vms = ["app1_vm01", "app1_vm02"]
    rules = {
      "app1" = {
        health_check_port = "80"
        listener_rules = {
          "1" = {
            target_protocol = "HTTP"
            target_port     = 80
            path_pattern    = ["/"]
          }
        }
      }
    }
    vpc             = "security_vpc_ingress"
    subnet_group    = "alb"
    security_groups = "application_load_balancer"
  }
  "app2-alb" = {
    vms = ["app2_vm01", "app2_vm02"]
    rules = {
      "app2" = {
        health_check_port = "80"
        listener_rules = {
          "1" = {
            target_protocol = "HTTP"
            target_port     = 80
            path_pattern    = ["/"]
          }
        }
      }
    }
    vpc             = "security_vpc_ingress"
    subnet_group    = "alb"
    security_groups = "application_load_balancer"
  }
}

### SPOKE VMS
spoke_vms = {
  "app1_vm01" = {
    az             = "eu-west-1a"
    vpc            = "app1_vpc"
    subnet_group   = "app1_vm"
    security_group = "app1_vm"
  }
  "app1_vm02" = {
    az             = "eu-west-1b"
    vpc            = "app1_vpc"
    subnet_group   = "app1_vm"
    security_group = "app1_vm"
  }
  "app2_vm01" = {
    az             = "eu-west-1a"
    vpc            = "app2_vpc"
    subnet_group   = "app2_vm"
    security_group = "app2_vm"
  }
  "app2_vm02" = {
    az             = "eu-west-1b"
    vpc            = "app2_vpc"
    subnet_group   = "app2_vm"
    security_group = "app2_vm"
  }
}
