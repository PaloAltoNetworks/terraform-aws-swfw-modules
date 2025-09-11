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
    name = "app1-spoke-vpc"
    cidr = "10.104.0.0/16"
    security_groups = {
      app1_vm = {
        name = "app1_vm"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["10.104.2.0/24", "10.104.130.0/24"]
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["10.104.2.0/24", "10.104.130.0/24"]
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
      "10.104.0.0/24"   = { az = "eu-west-1a", subnet_group = "app1_vm" }
      "10.104.128.0/24" = { az = "eu-west-1b", subnet_group = "app1_vm" }
      "10.104.2.0/24"   = { az = "eu-west-1a", subnet_group = "public" }
      "10.104.130.0/24" = { az = "eu-west-1b", subnet_group = "public" }
      "10.104.3.0/24"   = { az = "eu-west-1a", subnet_group = "cngfw_subnet" }
      "10.104.131.0/24" = { az = "eu-west-1b", subnet_group = "cngfw_subnet" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc           = "app1_vpc"
        subnet_group  = "app1_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      vm_lb_az1 = {
        vpc           = "app1_vpc"
        subnet_group  = "app1_vm"
        to_cidr       = "10.104.2.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      vm_lb_az2 = {
        vpc           = "app1_vpc"
        subnet_group  = "app1_vm"
        to_cidr       = "10.104.130.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      cngfw_default = {
        vpc           = "app1_vpc"
        subnet_group  = "cngfw_subnet"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_nat_gw"
        next_hop_type = "nat_gateway"
      }
      public_default = {
        vpc           = "app1_vpc"
        subnet_group  = "public"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app1_vpc"
        next_hop_type = "internet_gateway"
      }
      public_app_az1 = {
        vpc           = "app1_vpc"
        subnet_group  = "public"
        to_cidr       = "10.104.0.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
      public_app_az2 = {
        vpc           = "app1_vpc"
        subnet_group  = "public"
        to_cidr       = "10.104.128.0/24"
        next_hop_key  = "cngfw_endpoint_app1"
        next_hop_type = "gwlbe_endpoint"
      }
    }
  }
  app2_vpc = {
    name = "app2-spoke-vpc"
    cidr = "10.105.0.0/16"
    security_groups = {
      app2_vm = {
        name = "app2_vm"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["10.105.2.0/24", "10.105.130.0/24"]
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["10.105.2.0/24", "10.105.130.0/24"]
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
      "10.105.0.0/24"   = { az = "eu-west-1a", subnet_group = "app2_vm" }
      "10.105.128.0/24" = { az = "eu-west-1b", subnet_group = "app2_vm" }
      "10.105.2.0/24"   = { az = "eu-west-1a", subnet_group = "public" }
      "10.105.130.0/24" = { az = "eu-west-1b", subnet_group = "public" }
      "10.105.3.0/24"   = { az = "eu-west-1a", subnet_group = "cngfw_subnet" }
      "10.105.131.0/24" = { az = "eu-west-1b", subnet_group = "cngfw_subnet" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      vm_default = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_vm"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      vm_lb_az1 = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_vm"
        to_cidr       = "10.105.2.0/24"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      vm_lb_az2 = {
        vpc           = "app2_vpc"
        subnet_group  = "app2_vm"
        to_cidr       = "10.105.130.0/24"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      cngfw_default = {
        vpc           = "app2_vpc"
        subnet_group  = "cngfw_subnet"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_nat_gw"
        next_hop_type = "nat_gateway"
      }
      public_default = {
        vpc           = "app2_vpc"
        subnet_group  = "public"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "app2_vpc"
        next_hop_type = "internet_gateway"
      }
      public_app_az1 = {
        vpc           = "app2_vpc"
        subnet_group  = "public"
        to_cidr       = "10.105.0.0/24"
        next_hop_key  = "cngfw_endpoint_app2"
        next_hop_type = "gwlbe_endpoint"
      }
      public_app_az2 = {
        vpc           = "app2_vpc"
        subnet_group  = "public"
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
    name         = "app1-natgw"
    vpc          = "app1_vpc"
    subnet_group = "public"
  }
  app2_nat_gw = {
    name         = "app2-natgw"
    vpc          = "app2_vpc"
    subnet_group = "public"
  }
}

### Cloud NGFW
cloudngfws = {
  cloudngfws_security_app1 = {
    name         = "cloudngfw01"
    subnet_group = "cngfw_subnet"
    vpc          = "app1_vpc"
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
    name         = "cloudngfw02"
    subnet_group = "cngfw_subnet"
    vpc          = "app2_vpc"
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
    subnet_group    = "cngfw_subnet"
    act_as_next_hop = false
    delay           = 60
    cloudngfw_key   = "cloudngfws_security_app1"
  }
  cngfw_endpoint_app2 = {
    name            = "cngfw_app2_endpoint"
    vpc             = "app2_vpc"
    subnet_group    = "cngfw_subnet"
    act_as_next_hop = false
    delay           = 60
    cloudngfw_key   = "cloudngfws_security_app2"
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

### INBOUND LOADBALANCERS
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
    vpc             = "app1_vpc"
    subnet_group    = "public"
    security_groups = "app1_lb"
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
    vpc             = "app2_vpc"
    subnet_group    = "public"
    security_groups = "app2_lb"
  }
}
