### GENERAL
region      = "eu-central-1" # TODO: update here
name_prefix = "example-"     # TODO: update here

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-frankfurt" # TODO: update here

### VPC
vpcs = {
  security_vpc = {
    name = "security-vpc"
    cidr = "10.100.0.0/16"
    nacls = {
      trusted_path_monitoring = {
        name = "trusted-path-monitoring"
        rules = {
          block_outbound_icmp_1 = {
            rule_number = 110
            egress      = true
            protocol    = "icmp"
            rule_action = "deny"
            cidr_block  = "10.100.1.0/24"
          }
          block_outbound_icmp_2 = {
            rule_number = 120
            egress      = true
            protocol    = "icmp"
            rule_action = "deny"
            cidr_block  = "10.100.65.0/24"
          }
          allow_other_outbound = {
            rule_number = 200
            egress      = true
            protocol    = "-1"
            rule_action = "allow"
            cidr_block  = "0.0.0.0/0"
          }
          allow_inbound = {
            rule_number = 300
            egress      = false
            protocol    = "-1"
            rule_action = "allow"
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
          /* Uncomment the following section in case of direct firewall mgmt access required 
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          */
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
    }
    subnets = {
      # Value of `nacl` must match key of objects stored in `nacls`
      "10.100.0.0/24"  = { az = "eu-central-1a", subnet_group = "mgmt" }
      "10.100.64.0/24" = { az = "eu-central-1b", subnet_group = "mgmt" }
      "10.100.1.0/24"  = { az = "eu-central-1a", subnet_group = "private", nacl = "trusted_path_monitoring" }
      "10.100.65.0/24" = { az = "eu-central-1b", subnet_group = "private", nacl = "trusted_path_monitoring" }
      "10.100.2.0/24"  = { az = "eu-central-1a", subnet_group = "public" }
      "10.100.66.0/24" = { az = "eu-central-1b", subnet_group = "public" }
      "10.100.3.0/24"  = { az = "eu-central-1a", subnet_group = "tgw_attach" }
      "10.100.67.0/24" = { az = "eu-central-1b", subnet_group = "tgw_attach" }
      "10.100.4.0/24"  = { az = "eu-central-1a", subnet_group = "gwlbe_outbound" }
      "10.100.68.0/24" = { az = "eu-central-1b", subnet_group = "gwlbe_outbound" }
      "10.100.5.0/24"  = { az = "eu-central-1a", subnet_group = "gwlb" }
      "10.100.69.0/24" = { az = "eu-central-1b", subnet_group = "gwlb" }
      "10.100.10.0/24" = { az = "eu-central-1a", subnet_group = "gwlbe_eastwest" }
      "10.100.74.0/24" = { az = "eu-central-1b", subnet_group = "gwlbe_eastwest" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      mgmt_default = {
        vpc           = "security_vpc"
        subnet_group  = "mgmt"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
      mgmt_panorama = {
        vpc           = "security_vpc"
        subnet_group  = "mgmt"
        to_cidr       = "10.255.0.0/16"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      mgmt_rfc1918 = {
        vpc           = "security_vpc"
        subnet_group  = "mgmt"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      tgw_rfc1918 = {
        vpc           = "security_vpc"
        subnet_group  = "tgw_attach"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security_gwlb_eastwest"
        next_hop_type = "gwlbe_endpoint"
      }
      tgw_default = {
        vpc           = "security_vpc"
        subnet_group  = "tgw_attach"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_gwlb_outbound"
        next_hop_type = "gwlbe_endpoint"
      }
      public_default = {
        vpc           = "security_vpc"
        subnet_group  = "public"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "security_vpc"
        next_hop_type = "internet_gateway"
      }
      gwlbe_outbound_rfc1918 = {
        vpc           = "security_vpc"
        subnet_group  = "gwlbe_outbound"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
      }
      gwlbe_eastwest_rfc1918 = {
        vpc           = "security_vpc"
        subnet_group  = "gwlbe_eastwest"
        to_cidr       = "10.0.0.0/8"
        next_hop_key  = "security"
        next_hop_type = "transit_gateway_attachment"
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
    }
    subnets = {
      "10.104.0.0/24"   = { az = "eu-central-1a", subnet_group = "app1_vm" }
      "10.104.128.0/24" = { az = "eu-central-1b", subnet_group = "app1_vm" }
      "10.104.2.0/24"   = { az = "eu-central-1a", subnet_group = "app1_lb" }
      "10.104.130.0/24" = { az = "eu-central-1b", subnet_group = "app1_lb" }
      "10.104.3.0/24"   = { az = "eu-central-1a", subnet_group = "app1_gwlbe" }
      "10.104.131.0/24" = { az = "eu-central-1b", subnet_group = "app1_gwlbe" }
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
    }
    subnets = {
      "10.105.0.0/24"   = { az = "eu-central-1a", subnet_group = "app2_vm" }
      "10.105.128.0/24" = { az = "eu-central-1b", subnet_group = "app2_vm" }
      "10.105.2.0/24"   = { az = "eu-central-1a", subnet_group = "app2_lb" }
      "10.105.130.0/24" = { az = "eu-central-1b", subnet_group = "app2_lb" }
      "10.105.3.0/24"   = { az = "eu-central-1a", subnet_group = "app2_gwlbe" }
      "10.105.131.0/24" = { az = "eu-central-1b", subnet_group = "app2_gwlbe" }
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
  app1_inbound = {
    name                     = "app1-gwlb-endpoint"
    gwlb                     = "security_gwlb"
    vpc                      = "app1_vpc"
    subnet_group             = "app1_gwlbe"
    act_as_next_hop          = true
    from_igw_to_vpc          = "app1_vpc"
    from_igw_to_subnet_group = "app1_lb"
  }
  app2_inbound = {
    name                     = "app2-gwlb-endpoint"
    gwlb                     = "security_gwlb"
    vpc                      = "app2_vpc"
    subnet_group             = "app2_gwlbe"
    act_as_next_hop          = true
    from_igw_to_vpc          = "app2_vpc"
    from_igw_to_subnet_group = "app2_lb"
  }
}

### VM-SERIES
vmseries_asgs = {
  main_asg = {
    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`. Delete map if SCM bootstrap required.
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

    /* Uncomment this section if SCM bootstrap required (PAN-OS version 11.0 or higher) 

    bootstrap_options = {
      mgmt-interface-swap                   = "enable"
      panorama-server                       = "cloud"                                                                          # TODO: update here
      dgname                                = "scm_folder_name"                                                                # TODO: update here
      dhcp-send-hostname                    = "yes"                                                                            # TODO: update here
      dhcp-send-client-id                   = "yes"                                                                            # TODO: update here
      dhcp-accept-server-hostname           = "yes"                                                                            # TODO: update here
      dhcp-accept-server-domain             = "yes"                                                                            # TODO: update here
      plugin-op-commands                    = "aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable,advance-routing:enable" # TODO: update here
      vm-series-auto-registration-pin-id    = "1234ab56-1234-12a3-a1bc-a1bc23456de7"                                           # TODO: update here
      vm-series-auto-registration-pin-value = "12ab3c456d78901e2f3abc456d78ef9a"                                               # TODO: update here
      authcodes                             = "D1234567"                                                                       # TODO: update here
    }
    */

    panos_version = "11.1.4-h7"     # TODO: update here
    ebs_kms_id    = "alias/aws/ebs" # TODO: update here

    # Value of `vpc` must match key of objects stored in `vpcs`
    vpc = "security_vpc"

    # Value of `gwlb` must match key of objects stored in `gwlbs`
    gwlb = "security_gwlb"

    zones = {
      "01" = "eu-central-1a"
      "02" = "eu-central-1b"
    }

    interfaces = {
      private = {
        device_index      = 0
        security_group    = "vmseries_private"
        subnet_group      = "private"
        create_public_ip  = false
        source_dest_check = false
      }
      mgmt = {
        device_index      = 1
        security_group    = "vmseries_mgmt"
        subnet_group      = "mgmt"
        create_public_ip  = true
        source_dest_check = true
      }
      public = {
        device_index      = 2
        security_group    = "vmseries_public"
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

    asg = {
      desired_cap                     = 2
      min_size                        = 2
      max_size                        = 4
      lambda_execute_pip_install_once = true
    }

    scaling_plan = {
      enabled                   = true               # TODO: update here
      metric_name               = "panSessionActive" # TODO: update here
      estimated_instance_warmup = 900                # TODO: update here
      target_value              = 75                 # TODO: update here
      statistic                 = "Average"          # TODO: update here
      cloudwatch_namespace      = "asg-vmseries"     # TODO: update here
      tags = {
        ManagedBy = "terraform"
      }
    }

    launch_template_version = "$Latest"
    instance_refresh        = null

    delicense = {
      enabled        = false
      ssm_param_name = null
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
    az             = "eu-central-1a"
    vpc            = "app1_vpc"
    subnet_group   = "app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app1_vm02" = {
    az             = "eu-central-1b"
    vpc            = "app1_vpc"
    subnet_group   = "app1_vm"
    security_group = "app1_vm"
    type           = "t2.micro"
  }
  "app2_vm01" = {
    az             = "eu-central-1a"
    vpc            = "app2_vpc"
    subnet_group   = "app2_vm"
    security_group = "app2_vm"
    type           = "t2.micro"
  }
  "app2_vm02" = {
    az             = "eu-central-1b"
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