### Provider
provider_account = ""
provider_role    = "cloudngfw"

### GENERAL
region      = "eu-west-1"  # TODO: update here
name_prefix = "example-" # TODO: update here

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-ssh-key" # TODO: update here


### VPC
vpcs = {
  security_vpc_ewob = {
    name            = "security_vpc_ewob"
    cidr            = "10.100.0.0/16"
    nacls           = {}
    security_groups = {}
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf
      # Value of `nacl` must match key of objects stored in `nacls`
      "10.100.0.0/24"  = { az = "eu-west-1a", set = "tgw_attach" }
      "10.100.64.0/24" = { az = "eu-west-1b", set = "tgw_attach" }
      "10.100.1.0/24"  = { az = "eu-west-1a", set = "cngfw_subnet" }
      "10.100.65.0/24" = { az = "eu-west-1b", set = "cngfw_subnet" }
      "10.100.2.0/24"  = { az = "eu-west-1a", set = "natgw" }
      "10.100.66.0/24" = { az = "eu-west-1b", set = "natgw" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      tgw_default = {
        vpc           = "security_vpc_ewob"
        subnet        = "tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_endpoint_ewob"
        next_hop_type = "gwlbe_endpoint"
      }
      eastwest_rfc1918 = {
        vpc           = "security_vpc_ewob"
        subnet        = "cngfw_subnet"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security_ewob"
        next_hop_type = "transit_gateway_attachment"
      }
      cngfw_default = {
        vpc           = "security_vpc_ewob"
        subnet        = "cngfw_subnet"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_nat_gw"
        next_hop_type = "nat_gateway"
      }
      nat_default = {
        vpc           = "security_vpc_ewob"
        subnet        = "natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc_ewob"
        next_hop_type = "internet_gateway"
      }
      nat_app = {
        vpc           = "security_vpc_ewob"
        subnet        = "natgw"
        to_cidr       = "10.104.0.0/16"
        next_hop_key  = "cngfw_endpoint_ewob"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_app2 = {
        vpc           = "security_vpc_ewob"
        subnet        = "natgw"
        to_cidr       = "10.105.0.0/16"
        next_hop_key  = "cngfw_endpoint_ewob"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
  security_vpc_in = {
    name  = "security_vpc_in"
    cidr  = "10.101.0.0/16"
    nacls = {}
    security_groups = {
      app_lb = {
        name = "app_lb"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["130.41.251.148/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["130.41.251.148/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf
      # Value of `nacl` must match key of objects stored in `nacls`
      "10.101.0.0/24"   = { az = "eu-west-1a", set = "tgw_attach" }
      "10.101.64.0/24"  = { az = "eu-west-1b", set = "tgw_attach" }
      "10.101.1.0/24"   = { az = "eu-west-1a", set = "cngfw_subnet" }
      "10.101.65.0/24"  = { az = "eu-west-1b", set = "cngfw_subnet" }
      "10.101.2.0/24"   = { az = "eu-west-1a", set = "app_lb" }
      "10.101.130.0/24" = { az = "eu-west-1b", set = "app_lb" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      tgw_default = {
        vpc           = "security_vpc_in"
        subnet        = "tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_endpoint_in"
        next_hop_type = "gwlbe_endpoint"
      }
      eastwest_rfc1918 = {
        vpc           = "security_vpc_in"
        subnet        = "cngfw_subnet"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security_in"
        next_hop_type = "transit_gateway_attachment"
      }
      spoke_app = {
        vpc           = "security_vpc_in"
        subnet        = "app_lb"
        to_cidr       = "10.104.0.0/16"
        next_hop_key  = "cngfw_endpoint_in"
        next_hop_type = "gwlbe_endpoint"
      }
      spoke_app2 = {
        vpc           = "security_vpc_in"
        subnet        = "app_lb"
        to_cidr       = "10.105.0.0/16"
        next_hop_key  = "cngfw_endpoint_in"
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
            cidr_blocks = ["1.1.1.1/32", "10.101.0.0/16", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32", "10.101.0.0/16", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32", "10.101.0.0/16", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.104.0.0/24"   = { az = "eu-west-1a", set = "app1_vm" }
      "10.104.128.0/24" = { az = "eu-west-1b", set = "app1_vm" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc           = "app1_vpc"
        subnet        = "app1_vm"
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
            cidr_blocks = ["1.1.1.1/32", "10.101.0.0/16", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32", "10.101.0.0/16", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32", "10.101.0.0/16", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.105.0.0/24"   = { az = "eu-west-1a", set = "app2_vm" }
      "10.105.128.0/24" = { az = "eu-west-1b", set = "app2_vm" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc           = "app2_vpc"
        subnet        = "app2_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2"
        next_hop_type = "transit_gateway_attachment"
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
    "from_security_vpc_ewob" = {
      create = true
      name   = "from_security_ewob"
    }
    "from_security_vpc_in" = {
      create = true
      name   = "from_security_in"
    }
    "from_spoke_vpc" = {
      create = true
      name   = "from_spokes"
    }
  }
  attachments = {
    # Value of `route_table` and `propagate_routes_to` must match `route_tables` stores under `tgw`
    security_in = {
      name                = "cloudngfw_in"
      vpc                 = "security_vpc_in"
      subnet              = "tgw_attach"
      route_table         = "from_security_vpc_ewob"
      propagate_routes_to = "from_spoke_vpc"
    }
    security_ewob = {
      name                = "cloudngfw_ewob"
      vpc                 = "security_vpc_ewob"
      subnet              = "tgw_attach"
      route_table         = "from_security_vpc_ewob"
      propagate_routes_to = "from_spoke_vpc"
    }
    app1 = {
      name                = "app1-spoke-vpc"
      vpc                 = "app1_vpc"
      subnet              = "app1_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc_ewob"
    }
    app2 = {
      name                = "app2-spoke-vpc"
      vpc                 = "app2_vpc"
      subnet              = "app2_vm"
      route_table         = "from_spoke_vpc"
      propagate_routes_to = "from_security_vpc_ewob"
    }
  }
}

### NAT GATEWAY
natgws = {
  security_nat_gw = {
    name   = "natgw"
    vpc    = "security_vpc_ewob"
    subnet = "natgw"
  }
}

### Cloud NGFW
cloudngfws = {
  cloudngfws_security_ewob = {
    name        = "cloudngfw01-ewob"
    vpc_subnet  = "security_vpc_ewob-cngfw_subnet"
    vpc         = "security_vpc_ewob"
    description = "Description"
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
      rule_2 = {
        rule_list                   = "LocalRule"
        priority                    = 1
        name                        = "eastwest"
        description                 = "East West test rule"
        source_cidrs                = ["any"]
        destination_cidrs           = ["10.104.0.0/16"]
        negate_destination          = false
        protocol                    = "application-default"
        applications                = ["any"]
        category_feeds              = null
        category_url_category_names = null
        action                      = "DenySilent"
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
  cloudngfws_security_in = {
    name        = "cloudngfw01-in"
    vpc_subnet  = "security_vpc_in-cngfw_subnet"
    vpc         = "security_vpc_in"
    description = "Description"
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
  cngfw_endpoint_ewob = {
    name            = "cngfw_endpoint_ewob"
    vpc             = "security_vpc_ewob"
    subnet          = "cngfw_subnet"
    act_as_next_hop = false
    delay           = 60
    cloudngfw       = "cloudngfws_security_ewob"
  }
  cngfw_endpoint_in = {
    name            = "cngfw_endpoint_in"
    vpc             = "security_vpc_in"
    subnet          = "cngfw_subnet"
    act_as_next_hop = false
    delay           = 60
    cloudngfw       = "cloudngfws_security_in"
  }
}

### SPOKE VMS
spoke_vms = {
  "app1_vm01" = {
    az             = "eu-west-1a"
    vpc            = "app1_vpc"
    subnet         = "app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app1_vm02" = {
    az             = "eu-west-1b"
    vpc            = "app1_vpc"
    subnet         = "app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app2_vm01" = {
    az             = "eu-west-1a"
    vpc            = "app2_vpc"
    subnet         = "app2_vm"
    security_group = "app2_vm"
    type           = "t2.micro"
  }
  "app2_vm02" = {
    az             = "eu-west-1b"
    vpc            = "app2_vpc"
    subnet         = "app2_vm"
    security_group = "app2_vm"
    type           = "t2.micro"
  }
}

### INBOUND LOADBALANCERS
inbound_albs = {
  "in-alb" = {
    vms = ["app1_vm01", "app1_vm02"]
    rules = {
      "app1" = {
        name                  = "app"
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
    vpc             = "security_vpc_in"
    subnet          = "app_lb"
    security_groups = "app_lb"
  }
}