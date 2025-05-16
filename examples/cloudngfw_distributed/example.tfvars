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
            cidr_blocks = ["1.1.1.1/32", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
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
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.104.0.0/24"   = { az = "eu-west-1a", set = "app1_vm", nacl = null }
      "10.104.128.0/24" = { az = "eu-west-1b", set = "app1_vm", nacl = null }
      "10.104.2.0/24"   = { az = "eu-west-1a", set = "app1_lb", nacl = null }
      "10.104.130.0/24" = { az = "eu-west-1b", set = "app1_lb", nacl = null }
      "10.104.3.0/24"   = { az = "eu-west-1a", set = "cngfw_subnet", nacl = null }
      "10.104.131.0/24" = { az = "eu-west-1b", set = "cngfw_subnet", nacl = null }
      "10.104.4.0/24"   = { az = "eu-west-1a", set = "natgw", nacl = null }
      "10.104.132.0/24" = { az = "eu-west-1b", set = "natgw", nacl = null }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc           = "app1_vpc"
        subnet        = "app1_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      vm_lb_az1 = {
        vpc           = "app1_vpc"
        subnet        = "app1_vm"
        to_cidr       = "10.104.2.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      vm_lb_az2 = {
        vpc           = "app1_vpc"
        subnet        = "app1_vm"
        to_cidr       = "10.104.130.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      cngfw_default = {
        vpc           = "app1_vpc"
        subnet        = "cngfw_subnet"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_nat_gw"
        next_hop_type = "nat_gateway"
      }
      lb_default = {
        vpc           = "app1_vpc"
        subnet        = "app1_lb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_vpc"
        next_hop_type = "internet_gateway"
      }
      lb_app_az1 = {
        vpc           = "app1_vpc"
        subnet        = "app1_lb"
        to_cidr       = "10.104.0.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      lb_app_az2 = {
        vpc           = "app1_vpc"
        subnet        = "app1_lb"
        to_cidr       = "10.104.128.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      natgw_default = {
        vpc           = "app1_vpc"
        subnet        = "natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_vpc"
        next_hop_type = "internet_gateway"
      }
      nat_app_az1 = {
        vpc           = "app1_vpc"
        subnet        = "natgw"
        to_cidr       = "10.104.0.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_app_az2 = {
        vpc           = "app1_vpc"
        subnet        = "natgw"
        to_cidr       = "10.104.128.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
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
            cidr_blocks = ["1.1.1.1/32", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
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
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
        }
      }
    }
    subnets = {
      # Do not modify value of `set=`, it is an internal identifier referenced by main.tf.
      "10.105.0.0/24"   = { az = "eu-west-1a", set = "app2_vm", nacl = null }
      "10.105.128.0/24" = { az = "eu-west-1b", set = "app2_vm", nacl = null }
      "10.105.2.0/24"   = { az = "eu-west-1a", set = "app2_lb", nacl = null }
      "10.105.130.0/24" = { az = "eu-west-1b", set = "app2_lb", nacl = null }
      "10.105.3.0/24"   = { az = "eu-west-1a", set = "cngfw_subnet", nacl = null }
      "10.105.131.0/24" = { az = "eu-west-1b", set = "cngfw_subnet", nacl = null }
      "10.105.4.0/24"   = { az = "eu-west-1a", set = "natgw", nacl = null }
      "10.105.132.0/24" = { az = "eu-west-1b", set = "natgw", nacl = null }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc           = "app2_vpc"
        subnet        = "app2_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      vm_lb_az1 = {
        vpc           = "app2_vpc"
        subnet        = "app2_vm"
        to_cidr       = "10.105.2.0/24"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      vm_lb_az2 = {
        vpc           = "app2_vpc"
        subnet        = "app2_vm"
        to_cidr       = "10.105.130.0/24"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      cngfw_default = {
        vpc           = "app2_vpc"
        subnet        = "cngfw_subnet"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_nat_gw"
        next_hop_type = "nat_gateway"
      }
      lb_default = {
        vpc           = "app2_vpc"
        subnet        = "app2_lb"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_vpc"
        next_hop_type = "internet_gateway"
      }
      lb_app_az1 = {
        vpc           = "app2_vpc"
        subnet        = "app2_lb"
        to_cidr       = "10.105.0.0/24"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      lb_app_az2 = {
        vpc           = "app2_vpc"
        subnet        = "app2_lb"
        to_cidr       = "10.105.128.0/24"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      natgw_default = {
        vpc           = "app2_vpc"
        subnet        = "natgw"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_vpc"
        next_hop_type = "internet_gateway"
      }
      nat_app_az1 = {
        vpc           = "app2_vpc"
        subnet        = "natgw"
        to_cidr       = "10.105.0.0/24"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      nat_app_az2 = {
        vpc           = "app2_vpc"
        subnet        = "natgw"
        to_cidr       = "10.105.128.0/24"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
}

### NAT GATEWAY
natgws = {
  app1_nat_gw = {
    name   = "app1-natgw"
    vpc    = "app1_vpc"
    subnet = "natgw"
  }
  app2_nat_gw = {
    name   = "app2-natgw"
    vpc    = "app2_vpc"
    subnet = "natgw"
  }
}

### Cloud NGFW
cloudngfws = {
  cloudngfws_security_app1 = {
    name        = "cloudngfw01"
    vpc_subnet  = "app1_vpc-cngfw_subnet"
    vpc         = "app1_vpc"
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
  cloudngfws_security_app2 = {
    name        = "cloudngfw02"
    vpc_subnet  = "app2_vpc-cngfw_subnet"
    vpc         = "app2_vpc"
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
  cngfw_endpoint_app1 = {
    name            = "cngfw_app1_endpoint"
    vpc             = "app1_vpc"
    subnet          = "cngfw_subnet"
    act_as_next_hop = false
    delay           = 60
    cloudngfw       = "cloudngfws_security_app1"
  }
  cngfw_endpoint_app2 = {
    name            = "cngfw_app2_endpoint"
    vpc             = "app2_vpc"
    subnet          = "cngfw_subnet"
    act_as_next_hop = false
    delay           = 60
    cloudngfw       = "cloudngfws_security_app2"
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
    vpc             = "app1_vpc"
    subnet          = "app1_lb"
    security_groups = "app1_lb"
  }
}