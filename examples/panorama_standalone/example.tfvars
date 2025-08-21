### General
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
  management_vpc = {
    name  = "management-vpc"
    cidr  = "10.255.0.0/16"
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
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
          ssh = {
            description = "Permit SSH"
            type        = "ingress", from_port = "22", to_port = "22", protocol = "tcp"
            cidr_blocks = ["1.1.1.1/32"] # TODO: update here (replace 1.1.1.1/32 with your IP range)
          }
        }
      }
    }
    subnets = {
      "10.255.0.0/24" = { az = "eu-west-1a", subnet_group = "mgmt" }
      "10.255.1.0/24" = { az = "eu-west-1b", subnet_group = "mgmt" }
    }
    routes = {
      # Value of `next_hop_key` must match keys used to create TGW attachment, IGW, GWLB endpoint or other resources
      # Value of `next_hop_type` is internet_gateway, nat_gateway, transit_gateway_attachment or gwlbe_endpoint
      mgmt_default = {
        vpc           = "management_vpc"
        subnet_group  = "mgmt"
        to_cidr       = "0.0.0.0/0"
        next_hop_key  = "management_vpc"
        next_hop_type = "internet_gateway"
      }
    }
  }
}

### PANORAMA instances
panoramas = {
  panorama_ha_pair = {
    instances = {
      "primary" = {
        az                 = "eu-west-1a"
        private_ip_address = "10.255.0.4"
      }
      "secondary" = {
        az                 = "eu-west-1b"
        private_ip_address = "10.255.1.4"
      }
    }

    panos_version = "11.1.4-h7"

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
      encrypted = true
    }

    iam = {
      create_role = true
      role_name   = "panorama"
    }
  }
}
