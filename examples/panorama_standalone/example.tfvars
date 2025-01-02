### General
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
  management_vpc = {
    name = "management-vpc"
    cidr_block = {
      ipv4 = "10.255.0.0/16"
    }
    subnets = {
      mgmta = { az = "a", cidr_block = "10.255.0.0/24", subnet_group = "mgmt", name = "mgmt1" }
      mgmtb = { az = "b", cidr_block = "10.255.1.0/24", subnet_group = "mgmt", name = "mgmt2" }
    }
    routes = {
      # Value of `next_hop_key` must match keys used to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      mgmt_defaulta = {
        route_table   = "mgmta"
        to_cidr       = "0.0.0.0/0"
        az            = "a"
        next_hop_type = "internet_gateway"
        next_hop_key  = "management_vpc"
      }
      mgmt_defaultb = {
        route_table   = "mgmtb"
        to_cidr       = "0.0.0.0/0"
        az            = "b"
        next_hop_type = "internet_gateway"
        next_hop_key  = "management_vpc"
      }
    }
    nacls = {}
    security_groups = {
      panorama_mgmt = {
        name = "panorama_mgmt"
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
        }
      }
    }
  }
}

### PANORAMA instances
panoramas = {
  panorama_ha_pair = {
    instances = {
      "primary" = {
        az                 = "a"
        private_ip_address = "10.255.0.4"
      }
      "secondary" = {
        az                 = "b"
        private_ip_address = "10.255.1.4"
      }
    }

    panos_version = "10.2.8"

    network = {
      vpc              = "management_vpc"
      subnet_group     = "mgmt"
      security_group   = "panorama_mgmt"
      create_public_ip = true
    }

    ebs = {
      volumes = [
        {
          name            = "ebs-1"
          ebs_device_name = "/dev/sdb"
          ebs_size        = "2000"
        },
        {
          name            = "ebs-2"
          ebs_device_name = "/dev/sdc"
          ebs_size        = "2000"
        }
      ]
      encrypted     = true
      kms_key_alias = "alias/aws/ebs"
    }

    iam = {
      create_role = true
      role_name   = "panorama"
    }

    enable_imdsv2 = false
  }
}
