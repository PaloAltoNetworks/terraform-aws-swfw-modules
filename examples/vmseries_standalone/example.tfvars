### GENERAL
region      = "eu-west-1" # TODO: update here
name_prefix = "example-"  # TODO: update here

tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-ssh-key" # TODO: update here

### VPC
vpcs = {
  security_vpc = {
    name = "security-vpc"
    cidr_block = {
      ipv4                             = "10.100.0.0/16"
      assign_generated_ipv6_cidr_block = false
    }
    subnets = {
      # Value of `nacl` must match key of objects stored in `nacls`
      mgmta = { az = "a", cidr_block = "10.100.0.0/24", subnet_group = "mgmt", name = "mgmt" }
    }
    routes = {
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      mgmt_defaulta = {
        route_table      = "mgmta"
        to_cidr          = "0.0.0.0/0"
        az               = "a"
        destination_type = "ipv4"
        next_hop_type    = "internet_gateway"
        next_hop_key     = "security_vpc"
      }
    }
    nacls = {}
    security_groups = {
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
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"] # TODO: update here (replace 0.0.0.0/0 by your IP range)
          }
        }
      }
    }
  }
}

### VM-SERIES
vmseries = {
  vmseries = {
    instances = {
      "01" = { az = "a" }
    }

    bucket_name = "bucket-paloaltonetworks"

    # Value of `panorama-server`, `auth-key`, `dgname`, `tplname` can be taken from plugin `sw_fw_license`
    bootstrap_options = {
      mgmt-interface-swap         = "disable"
      panorama-server             = "10.10.0.4"                                               # TODO: update here
      tplname                     = "aws_template"                                            # TODO: update here
      dgname                      = "aws_device_group"                                        # TODO: update here
      plugin-op-commands          = "aws-gwlb-inspect:enable,aws-gwlb-overlay-routing:enable" # TODO: update here
      dhcp-send-hostname          = "no"                                                      # TODO: update here
      dhcp-send-client-id         = "no"                                                      # TODO: update here
      dhcp-accept-server-hostname = "no"                                                      # TODO: update here
      dhcp-accept-server-domain   = "no"                                                      # TODO: update here
    }

    panos_version = "11.1.2-h3"     # TODO: update here
    ebs_kms_id    = "alias/aws/ebs" # TODO: update here

    # Value of `vpc` must match key of objects stored in `vpcs`
    vpc = "security_vpc"

    interfaces = {
      mgmt = {
        device_index = 0
        private_ip = {
          "01" = "10.100.0.4"
        }
        security_group     = "vmseries_mgmt"
        vpc                = "security_vpc"
        subnet_group       = "mgmt"
        ipv6_address_count = 0
        create_public_ip   = true
        source_dest_check  = true
        eip_allocation_id = {
          "01" = null
        }
      }
    }
  }
}
