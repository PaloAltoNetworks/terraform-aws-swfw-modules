### GENERAL
region      = "eu-west-1" # TODO: update here
name_prefix = "example-"  # TODO: update here

global_tags = {
  ManagedBy   = "terraform"
  Application = "Palo Alto Networks VM-Series NGFW"
  Owner       = "PS Team"
}

ssh_key_name = "example-ssh-key" # TODO: update here

### VPC
vpcs = {
  security_vpc = {
    name                             = "security-vpc"
    cidr                             = "10.100.0.0/16"
    assign_generated_ipv6_cidr_block = true
    nacls                            = {}
    security_groups = {
      vmseries_mgmt = {
        name = "vmseries_mgmt"
        rules = {
          all_outbound = {
            description = "Permit All traffic outbound"
            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"]
          }
          all_outbound_ipv6 = {
            description      = "Permit All traffic outbound"
            type             = "egress", from_port = "0", to_port = "0", protocol = "-1"
            ipv6_cidr_blocks = ["::/0"]
          }
          https = {
            description = "Permit HTTPS"
            type        = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          https_ipv6 = {
            description      = "Permit HTTPS"
            type             = "ingress", from_port = "443", to_port = "443", protocol = "tcp"
            ipv6_cidr_blocks = ["2001:DB8::1"] # TODO: update here (replace 2001:DB8::1 with your IP range)
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          ssh_ipv6 = {
            description      = "Permit SSH"
            type             = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            ipv6_cidr_blocks = ["2001:DB8::1"] # TODO: update here (replace 2001:DB8::1 with your IP range)
          }
        }
      }
    }
    subnets = {
      # Value of `nacl` must match key of objects stored in `nacls`
      "10.100.0.0/24" = { az = "eu-west-1a", subnet_group = "mgmt", nacl = null, ipv6_index = 1 }
    }
    routes = {
      # Value of `vpc_subnet` is built from key of VPCs concatenate with `-` and key of subnet in format: `VPCKEY-SUBNETKEY`
      # Value of `next_hop_key` must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      mgmt_default = {
        vpc              = "security_vpc"
        subnet_group     = "mgmt"
        to_cidr          = "0.0.0.0/0"
        destination_type = "ipv4"
        next_hop_key     = "security_vpc"
        next_hop_type    = "internet_gateway"
      }
      mgmt_default_ipv6 = {
        vpc              = "security_vpc"
        subnet_group     = "mgmt"
        to_cidr          = "::/0"
        destination_type = "ipv6"
        next_hop_key     = "security_vpc"
        next_hop_type    = "internet_gateway"
      }
    }
  }
}

### VM-SERIES
vmseries = {
  vmseries = {
    instances = {
      "01" = { az = "eu-west-1a" }
    }

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

    panos_version = "11.1.4-h7"     # TODO: update here
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
        ipv6_address_count = 1
        create_public_ip   = true
        source_dest_check  = true
        eip_allocation_id = {
          "01" = null
        }
      }
    }
  }
}
