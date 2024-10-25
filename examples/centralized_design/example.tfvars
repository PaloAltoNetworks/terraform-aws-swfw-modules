### General
region      = "eu-west-1" # TODO: update here
name_prefix = "example-"  # TODO: update here

tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-ssh-key" # TODO: update here

### IAM Spoke definition
create_instance_profile = true
instance_profile_name   = "spoke_instance_profile"
role_name               = "spoke_role"
policy_arn              = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

### VPC
vpcs = {
  security_vpc = {
    name = "security-vpc"
    cidr_block = {
      ipv4 = "10.100.0.0/16"
    }
    subnets = {
      mgmta           = { az = "a", cidr_block = "10.100.0.0/24", subnet_group = "mgmt", name = "mgmt1" }
      mgmtb           = { az = "b", cidr_block = "10.100.64.0/24", subnet_group = "mgmt", name = "mgmt2" }
      privatea        = { az = "a", cidr_block = "10.100.1.0/24", subnet_group = "private", name = "private1", nacl = "trusted_path_monitoring" }
      privateb        = { az = "b", cidr_block = "10.100.65.0/24", subnet_group = "private", name = "private2", nacl = "trusted_path_monitoring" }
      publica         = { az = "a", cidr_block = "10.100.2.0/24", subnet_group = "public", name = "public1" }
      publicb         = { az = "b", cidr_block = "10.100.66.0/24", subnet_group = "public", name = "public2" }
      tgw_attacha     = { az = "a", cidr_block = "10.100.3.0/24", subnet_group = "tgw_attach", name = "tgw_attach1" }
      tgw_attachb     = { az = "b", cidr_block = "10.100.67.0/24", subnet_group = "tgw_attach", name = "tgw_attach2" }
      gwlbe_outbounda = { az = "a", cidr_block = "10.100.4.0/24", subnet_group = "gwlbe_outbound", name = "gwlbe_outbound1" }
      gwlbe_outboundb = { az = "b", cidr_block = "10.100.68.0/24", subnet_group = "gwlbe_outbound", name = "gwlbe_outbound2" }
      gwlba           = { az = "a", cidr_block = "10.100.5.0/24", subnet_group = "gwlb", name = "gwlb1" }
      gwlbb           = { az = "b", cidr_block = "10.100.69.0/24", subnet_group = "gwlb", name = "gwlb2" } # AWS reccomends to always go up to the last possible AZ for GWLB service
      gwlbe_eastwesta = { az = "a", cidr_block = "10.100.10.0/24", subnet_group = "gwlbe_eastwest", name = "gwlbe_eastwest1" }
      gwlbe_eastwestb = { az = "b", cidr_block = "10.100.74.0/24", subnet_group = "gwlbe_eastwest", name = "gwlbe_eastwest2" }
      alba            = { az = "a", cidr_block = "10.100.6.0/24", subnet_group = "alb", name = "alb1" }
      albb            = { az = "b", cidr_block = "10.100.70.0/24", subnet_group = "alb", name = "alb2" }
      nlba            = { az = "a", cidr_block = "10.100.7.0/24", subnet_group = "nlb", name = "nlb1" }
      nlbb            = { az = "b", cidr_block = "10.100.71.0/24", subnet_group = "nlb", name = "nlb2" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway or gwlbe_endpoint
      mgmt_defaulta = {
        route_table   = "mgmta"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "internet_gateway"
        next_hop_key  = "security_vpc"
      }
      mgmt_defaultb = {
        route_table   = "mgmtb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "internet_gateway"
        next_hop_key  = "security_vpc"
      }
      mgmt_panoramaa = {
        route_table   = "mgmta"
        to_cidr       = "10.255.0.0/16"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      mgmt_panoramab = {
        route_table   = "mgmtb"
        to_cidr       = "10.255.0.0/16"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      mgmt_rfc1918a = {
        route_table   = "mgmta"
        to_cidr       = "10.0.0.0/8"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      mgmt_rfc1918b = {
        route_table   = "mgmtb"
        to_cidr       = "10.0.0.0/8"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      tgw_defaulta = {
        route_table   = "tgw_attacha"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "gwlbe_endpoint"
        next_hop_key  = "security_gwlb_outbound"
      }
      tgw_defaultb = {
        route_table   = "tgw_attachb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "gwlbe_endpoint"
        next_hop_key  = "security_gwlb_outbound"
      }
      tgw_rfc1918a = {
        route_table   = "tgw_attacha"
        to_cidr       = "10.0.0.0/8"
        az            = "a"
        next_hop_type = "gwlbe_endpoint"
        next_hop_key  = "security_gwlb_eastwest"
      }
      tgw_rfc1918b = {
        route_table   = "tgw_attachb"
        to_cidr       = "10.0.0.0/8"
        az            = "b"
        next_hop_type = "gwlbe_endpoint"
        next_hop_key  = "security_gwlb_eastwest"
      }
      public_defaulta = {
        route_table   = "publica"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "internet_gateway"
        next_hop_key  = "security_vpc"
      }
      public_defaultb = {
        route_table   = "publicb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "internet_gateway"
        next_hop_key  = "security_vpc"
      }
      gwlbe_outbound_rfc1918a = {
        route_table   = "gwlbe_outbounda"
        to_cidr       = "10.0.0.0/8"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      gwlbe_outbound_rfc1918b = {
        route_table   = "gwlbe_outboundb"
        to_cidr       = "10.0.0.0/8"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      gwlbe_eastwest_rfc1918a = {
        route_table   = "gwlbe_eastwesta"
        to_cidr       = "10.0.0.0/8"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      gwlbe_eastwest_rfc1918b = {
        route_table   = "gwlbe_eastwestb"
        to_cidr       = "10.0.0.0/8"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      private_app1a = {
        route_table   = "privatea"
        to_cidr       = "10.104.0.0/16"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      private_app1b = {
        route_table   = "privateb"
        to_cidr       = "10.104.0.0/16"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      private_app2a = {
        route_table   = "privatea"
        to_cidr       = "10.105.0.0/16"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      private_app2b = {
        route_table   = "privateb"
        to_cidr       = "10.105.0.0/16"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "security"
      }
      alb_defaulta = {
        route_table   = "alba"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "internet_gateway"
        next_hop_key  = "security_vpc"
      }
      alb_defaultb = {
        route_table   = "albb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "internet_gateway"
        next_hop_key  = "security_vpc"
      }
      nlb_defaulta = {
        route_table   = "nlba"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "internet_gateway"
        next_hop_key  = "security_vpc"
      }
      nlb_defaultb = {
        route_table   = "nlbb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "internet_gateway"
        next_hop_key  = "security_vpc"
      }
    }
    nacls = {
      trusted_path_monitoring = {
        name = "trusted-path-monitoring"
        rules = {
          block_outbound_icmp_1 = {
            rule_number = 110
            type        = "egress"
            protocol    = "icmp"
            action      = "deny"
            cidr_block  = "10.100.1.0/24"
          }
          block_outbound_icmp_2 = {
            rule_number = 120
            type        = "egress"
            protocol    = "icmp"
            action      = "deny"
            cidr_block  = "10.100.65.0/24"
          }
          allow_other_outbound = {
            rule_number = 200
            type        = "egress"
            protocol    = "-1"
            action      = "allow"
            cidr_block  = "0.0.0.0/0"
          }
          allow_inbound = {
            rule_number = 300
            type        = "ingress"
            protocol    = "-1"
            action      = "allow"
            cidr_block  = "0.0.0.0/0"
          }
        }
      }
    }
    security_groups = {
      vmseries_private = {
        name = "vmseries_private"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          geneve = {
            description = "Permit GENEVE to GWLB subnets"
            type        = "ingress", from_port = "6081", to_port = "6081", protocol = "udp"
            cidr_blocks = [
              "10.100.5.0/24", "10.100.69.0/24"
            ]
          }
          health_probe = {
            description = "Permit Port 80 Health Probe to GWLB subnets"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = [
              "10.100.5.0/24", "10.100.69.0/24"
            ]
          }
        }
      }
      vmseries_mgmt = {
        name = "vmseries_mgmt"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24"] # TODO: update here
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24"] # TODO: update here
          }
          panorama_ssh = {
            description = "Permit Panorama SSH (Optional)"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["10.0.0.0/8"]
          }
        }
      }
      vmseries_public = {
        name = "vmseries_public"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here
          }
          health_probe_8081 = {
            description = "Permit Port 8081 Health Probe to ALB"
            type        = "ingress", from_port = "8081", to_port = "8081", protocol = "tcp"
            cidr_blocks = ["10.100.6.0/24", "10.100.70.0/24"]
          }
          health_probe_8082 = {
            description = "Permit Port 8082 Health Probe to ALB"
            type        = "ingress", from_port = "8082", to_port = "8082", protocol = "tcp"
            cidr_blocks = ["10.100.6.0/24", "10.100.70.0/24"]
          }
          health_probe_2021 = {
            description = "Permit Port 2021 Health Probe to NLB"
            type        = "ingress", from_port = "2021", to_port = "2021", protocol = "tcp"
            cidr_blocks = ["10.100.7.0/24", "10.100.71.0/24"]
          }
          health_probe_2022 = {
            description = "Permit Port 2022 Health Probe to NLB"
            type        = "ingress", from_port = "2022", to_port = "2022", protocol = "tcp"
            cidr_blocks = ["10.100.7.0/24", "10.100.71.0/24"]
          }
        }
      }
      application_load_balancer = {
        name = "alb"
        rules = {
          http_inbound_8081 = {
            description = "Permit incoming APP1 traffic"
            type        = "ingress", from_port = "8081", to_port = "8081", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
          http_inbound_8082 = {
            description = "Permit incoming APP2 traffic"
            type        = "ingress", from_port = "8082", to_port = "8082", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
          }
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
        }
      }
    }
  }
  app1_vpc = {
    name = "app1-spoke-vpc"
    cidr_block = {
      ipv4 = "10.104.0.0/16"
    }
    subnets = {
      app1_vma = { az = "a", cidr_block = "10.104.0.0/24", subnet_group = "app1_vm", name = "app1_vm1" }
      app1_vmb = { az = "b", cidr_block = "10.104.128.0/24", subnet_group = "app1_vm", name = "app1_vm2" }
      app1_lba = { az = "a", cidr_block = "10.104.2.0/24", subnet_group = "app1_lb", name = "app1_lb1" }
      app1_lbb = { az = "b", cidr_block = "10.104.130.0/24", subnet_group = "app1_lb", name = "app1_lb2" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway or gwlbe_endpoint
      vm_defaulta = {
        route_table   = "app1_vma"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "app1"
      }
      vm_defaultb = {
        route_table   = "app1_vmb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "app1"
      }
      lb_defaulta = {
        route_table   = "app1_lba"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "app1"
      }
      lb_defaultb = {
        route_table   = "app1_lbb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "app1"
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
          private_inbound = {
            description = "Permit All traffic inbound from 10.0.0.0/8"
            type        = "ingress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["10.0.0.0/8"] # TODO: update here
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here
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
      app2_vma = { az = "a", cidr_block = "10.105.0.0/24", subnet_group = "app2_vm", name = "app2_vm1" }
      app2_vmb = { az = "b", cidr_block = "10.105.128.0/24", subnet_group = "app2_vm", name = "app2_vm2" }
      app2_lba = { az = "a", cidr_block = "10.105.2.0/24", subnet_group = "app2_lb", name = "app2_lb1" }
      app2_lbb = { az = "b", cidr_block = "10.105.130.0/24", subnet_group = "app2_lb", name = "app2_lb2" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway or gwlbe_endpoint
      vm_defaulta = {
        route_table   = "app2_vma"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "app2"
      }
      vm_defaultb = {
        route_table   = "app2_vmb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "app2"
      }
      lb_defaulta = {
        route_table   = "app2_lba"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "transit_gateway"
        next_hop_key  = "app2"
      }
      lb_defaultb = {
        route_table   = "app2_lbb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "transit_gateway"
        next_hop_key  = "app2"
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
          private_inbound = {
            description = "Permit All traffic inbound from 10.0.0.0/8"
            type        = "ingress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["10.0.0.0/8"] # TODO: update here
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here
          }
          http = {
            description = "Permit HTTP"
            type        = "ingress", from_port = "80", to_port = "80", protocol = "tcp"
            cidr_blocks = ["130.41.247.0/24", "10.104.0.0/16", "10.105.0.0/16"] # TODO: update here
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
      name                = "vmseries"
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
natgws = {}

### GATEWAY LOADBALANCER
gwlbs = {
  security_gwlb = {
    name         = "security-gwlb"
    vpc          = "security_vpc"
    subnet_group = "gwlb"
  }
}
gwlb_endpoints = {
  # Value of `gwlb` must match key of objects stored in `gwlbs`
  # Value of `vpc` must match key of objects stored in `vpcs`
  security_gwlb_eastwest = {
    name            = "eastwest-gwlb-endpoint"
    gwlb            = "security_gwlb"
    vpc             = "security_vpc"
    subnet_group    = "gwlbe_eastwest"
    act_as_next_hop = false
  }
  security_gwlb_outbound = {
    name            = "outbound-gwlb-endpoint"
    gwlb            = "security_gwlb"
    vpc             = "security_vpc"
    subnet_group    = "gwlbe_outbound"
    act_as_next_hop = false
  }
}

### VM-SERIES
vmseries = {
  vmseries = {
    instances = {
      "01" = { az = "a" }
      "02" = { az = "b" }
    }

    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`
    bootstrap_options = {
      mgmt-interface-swap         = "enable"
      plugin-op-commands          = "panorama-licensing-mode-on,aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable" # TODO: update here
      panorama-server             = "10.255.0.10"                                                                        # TODO: update here
      auth-key                    = ""                                                                                   # TODO: update here
      dgname                      = "centralized"                                                                        # TODO: update here
      tplname                     = "centralized-stack"                                                                  # TODO: update here
      dhcp-send-hostname          = "yes"                                                                                # TODO: update here
      dhcp-send-client-id         = "yes"                                                                                # TODO: update here
      dhcp-accept-server-hostname = "yes"                                                                                # TODO: update here
      dhcp-accept-server-domain   = "yes"                                                                                # TODO: update here
    }

    panos_version = "10.2.9-h1"     # TODO: update here
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
      inbound = {}
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

    application_lb = {
      name           = "public-alb"
      subnet_group   = "alb"
      security_group = "application_load_balancer"
      rules = {
        "app1" = {
          protocol              = "HTTP"
          port                  = 8081
          health_check_port     = "8081"
          health_check_matcher  = "200"
          health_check_path     = "/"
          health_check_interval = 10
          listener_rules = {
            "1" = {
              target_protocol = "HTTP"
              target_port     = 8081
              path_pattern    = ["/"]
            }
          }
        }
        "app2" = {
          protocol              = "HTTP"
          port                  = 8082
          health_check_port     = "8082"
          health_check_matcher  = "200"
          health_check_path     = "/"
          health_check_interval = 10
          listener_rules = {
            "1" = {
              target_protocol = "HTTP"
              target_port     = 8082
              path_pattern    = ["/"]
            }
          }
        }
      }
    }
    network_lb = {
      name         = "public-nlb"
      subnet_group = "nlb"
      rules = {
        "ssh1" = {
          protocol           = "TCP"
          port               = "2021"
          target_type        = "ip"
          stickiness         = true
          preserve_client_ip = true
        }
        "ssh2" = {
          protocol           = "TCP"
          port               = "2022"
          target_type        = "ip"
          stickiness         = true
          preserve_client_ip = true
        }
      }
    }
  }
}

### PANORAMA
panorama_attachment = {
  transit_gateway_attachment_id = null            # TODO: update here
  vpc_cidr                      = "10.255.0.0/24" # TODO: update here
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
spoke_lbs = {
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
