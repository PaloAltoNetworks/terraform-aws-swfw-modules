---
short_title: Distributed Design
type: refarch
show_in_hub: true
swfw: cloudngfw
---
# Distributed Design model
- Cloud NGFW is deployed for each VPC which requires protection
- Reduces the possibility of misconfiguration and limits the scope of impact
- Each VPC is protected individually and blast radius is reduced through VPC isolation

![image](https://github.com/user-attachments/assets/2b8d22f5-ebf8-462e-90ff-cbed9084afd0)

## Prerequsite
- Enable Programmatic Access
To use the Terraform provider, you must first enable the Programmatic Access for your Cloud NGFW tenant. You can check this by navigating to the Settings section of the Cloud NGFW console. The steps to do this can be found [here](https://pan.dev/cloudngfw/aws/api/).
- Cloud NGFW assuming role
You will authenticate against your Cloud NGFW by assuming roles in your AWS account that are allowed to make API calls to the AWS API Gateway service. The associated tags with the roles dictate the type of Cloud NGFW programmatic access granted — Firewall Admin, RuleStack Admin, or Global Rulestack Admin.
```
resource "aws_iam_role" "ngfw_role" {
  name = "CloudNGFWRole"

  inline_policy {
    name = "apigateway_policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "execute-api:Invoke",
            "execute-api:ManageConnections"
          ],
          "Resource" : "arn:aws:execute-api:*:*:*"
        }
      ]
    })
  }

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      },
      {
        "Sid" : "",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            <your assume role ARN>
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    CloudNGFWRulestackAdmin       = "Yes"
    CloudNGFWFirewallAdmin        = "Yes"
    CloudNGFWGlobalRulestackAdmin = "Yes"
  }
}

```
- Update appriopate values for terraform variables ```var.provider_account``` and ``var.provider_role``.

## Spoke VMs

For the proposed example, the Spoke VMs are supporting ssm-agent. In addition, the VM ```user_data``` contains an installation of httpd service.</br>
To enable access from the session manager, the Internet connection for a public endpoint is required.

## Reference
<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.17 |
| <a name="requirement_cloudngfwaws"></a> [cloudngfwaws](#requirement\_cloudngfwaws) | 2.0.20 |
| <a name="requirement_time"></a> [time](#requirement\_time) | 0.11.1 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.17 |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app_alb"></a> [app\_alb](#module\_app\_alb) | ../../modules/alb | n/a |
| <a name="module_cloudngfw"></a> [cloudngfw](#module\_cloudngfw) | ../../modules/cloudngfw | n/a |
| <a name="module_gwlbe_endpoint"></a> [gwlbe\_endpoint](#module\_gwlbe\_endpoint) | ../../modules/gwlb_endpoint_set | n/a |
| <a name="module_natgw_set"></a> [natgw\_set](#module\_natgw\_set) | ../../modules/nat_gateway_set | n/a |
| <a name="module_subnet_sets"></a> [subnet\_sets](#module\_subnet\_sets) | ../../modules/subnet_set | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../../modules/vpc | n/a |
| <a name="module_vpc_routes"></a> [vpc\_routes](#module\_vpc\_routes) | ../../modules/vpc_route | n/a |

### Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.spoke_vm_iam_instance_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.spoke_vm_ec2_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.spoke_vm_iam_instance_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.spoke_vms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_ebs_default_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ebs_default_kms_key) | data source |
| [aws_kms_key.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/kms_key) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloudngfws"></a> [cloudngfws](#input\_cloudngfws) | A map defining Cloud NGFWs.<br/><br/>Following properties are available:<br/>- `name`       : name of CloudNGFW<br/>- `vpc_subnet` : key of the VPC and subnet connected by '-' character<br/>- `vpc`        : key of the VPC<br/>- `description`: Use for internal purposes.<br/>- `security_rules`: Security Rules definition.<br/>- `log_profiles`: Log Profile definition.<br/><br/>Example:<pre>cloudngfws = {<br/>  cloudngfws_security = {<br/>    name        = "cloudngfw01"<br/>    vpc_subnet  = "app_vpc-app_gwlbe"<br/>    vpc         = "app_vpc"<br/>    description = "description"<br/>    security_rules = <br/>    { <br/>      rule_1 = { <br/>        rule_list                   = "LocalRule"<br/>        priority                    = 3<br/>        name                        = "tf-security-rule"<br/>        description                 = "Also configured by Terraform"<br/>        source_cidrs                = ["any"]<br/>        destination_cidrs           = ["0.0.0.0/0"]<br/>        negate_destination          = false<br/>        protocol                    = "application-default"<br/>        applications                = ["any"]<br/>        category_feeds              = null<br/>        category_url_category_names = null<br/>        action                      = "Allow"<br/>        logging                     = true<br/>        audit_comment               = "initial config"<br/>      }<br/>    }<br/>    log_profiles = {  <br/>      dest_1 = {<br/>        create_cw        = true<br/>        name             = "PaloAltoCloudNGFW"<br/>        destination_type = "CloudWatchLogs"<br/>        log_type         = "THREAT"<br/>      }<br/>      dest_2 = {<br/>        create_cw        = true<br/>        name             = "PaloAltoCloudNGFW"<br/>        destination_type = "CloudWatchLogs"<br/>        log_type         = "TRAFFIC"<br/>      }<br/>      dest_3 = {<br/>        create_cw        = true<br/>        name             = "PaloAltoCloudNGFW"<br/>        destination_type = "CloudWatchLogs"<br/>        log_type         = "DECRYPTION"<br/>      }<br/>    }<br/>    profile_config = {<br/>      anti_spyware  = "BestPractice"<br/>      anti_virus    = "BestPractice"<br/>      vulnerability = "BestPractice"<br/>      file_blocking = "BestPractice"<br/>      url_filtering = "BestPractice"<br/>    }<br/>  }<br/>}</pre> | <pre>map(object({<br/>    name           = string<br/>    subnet_group   = string<br/>    vpc            = string<br/>    description    = optional(string, "Palo Alto Cloud NGFW")<br/>    security_rules = map(any)<br/>    log_profiles   = map(any)<br/>    profile_config = map(any)<br/>  }))</pre> | `{}` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags configured for all provisioned resources | `any` | n/a | yes |
| <a name="input_gwlb_endpoints"></a> [gwlb\_endpoints](#input\_gwlb\_endpoints) | A map defining GWLB endpoints.<br/><br/>Following properties are available:<br/>- `name`: name of the GWLB endpoint<br/>- `custom_names`: Optional map of names of the VPC Endpoints, used to override the default naming generated from the input `name`.<br/>  Each key is the Availability Zone identifier, for example `us-east-1b`.<br/>- `gwlb`: key of GWLB. Required when GWLB Endpoint must connect to GWLB's service name<br/>- `vpc`: key of VPC<br/>- `subnet_group`: key of the subnet\_group<br/>- `act_as_next_hop`: set to `true` if endpoint is part of an IGW route table e.g. for inbound traffic<br/>- `from_igw_to_vpc`: VPC to which traffic from IGW is routed to the GWLB endpoint<br/>- `from_igw_to_subnet_group` : subnet\_group to which traffic from IGW is routed to the GWLB endpoint<br/>- `cloudngfw_key`(optional): Key of the Cloud NGFW. Required when GWLB Endpoint must connect to Cloud NGFW's service name<br/><br/>Example:<pre>gwlb_endpoints = {<br/>  security_gwlb_eastwest = {<br/>    name            = "eastwest-gwlb-endpoint"<br/>    gwlb            = "security_gwlb"<br/>    vpc             = "security_vpc"<br/>    subnet_group    = "gwlbe_eastwest"<br/>    act_as_next_hop = false<br/>  }<br/>}</pre> | <pre>map(object({<br/>    name                     = string<br/>    custom_names             = optional(map(string), {})<br/>    gwlb                     = optional(string)<br/>    vpc                      = string<br/>    subnet_group             = string<br/>    act_as_next_hop          = bool<br/>    from_igw_to_vpc          = optional(string)<br/>    from_igw_to_subnet_group = optional(string)<br/>    delay                    = optional(number, 0)<br/>    tags                     = optional(map(string))<br/>    cloudngfw_key            = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources (VPCs, EC2 instances, autoscaling groups etc.) | `string` | n/a | yes |
| <a name="input_natgws"></a> [natgws](#input\_natgws) | A map defining NAT Gateways.<br/><br/>Following properties are available:<br/>- `nat_gateway_names`: A map, where each key is an Availability Zone name, for example "eu-west-1b". <br/>  Each value in the map is a custom name of a NAT Gateway in that Availability Zone.<br/>- `vpc`: key of the VPC<br/>- `subnet_group`: key of the subnet\_group<br/>- `nat_gateway_tags`: A map containing NAT GW tags<br/>- `create_eip`: Defaults to true, uses a data source to find EIP when set to false<br/>- `eips`: Optional map of Elastic IP attributes. Each key must be an Availability Zone name. <br/><br/>Example:<pre>natgws = {<br/>  sec_natgw = {<br/>    vpc = "security_vpc"<br/>    subnet_group = "natgw"<br/>    nat_gateway_names = {<br/>      "eu-west-1a" = "nat-gw-1"<br/>      "eu-west-1b" = "nat-gw-2"<br/>    }<br/>    eips ={<br/>      "eu-west-1a" = { <br/>        name = "natgw-1-pip"<br/>      }<br/>    }<br/>  }<br/>}</pre> | <pre>map(object({<br/>    create_nat_gateway = optional(bool, true)<br/>    nat_gateway_names  = optional(map(string), {})<br/>    vpc                = string<br/>    subnet_group       = string<br/>    nat_gateway_tags   = optional(map(string), {})<br/>    create_eip         = optional(bool, true)<br/>    eips = optional(map(object({<br/>      name      = optional(string)<br/>      public_ip = optional(string)<br/>      id        = optional(string)<br/>      eip_tags  = optional(map(string), {})<br/>    })), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_provider_account"></a> [provider\_account](#input\_provider\_account) | The AWS Account where the resources should be deployed. | `string` | n/a | yes |
| <a name="input_provider_role"></a> [provider\_role](#input\_provider\_role) | The predifined AWS assumed role for CloudNGFW. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region used to deploy whole infrastructure | `string` | n/a | yes |
| <a name="input_spoke_albs"></a> [spoke\_albs](#input\_spoke\_albs) | A map defining Application Load Balancers deployed in spoke VPCs.<br/><br/>Following properties are available:<br/>- `rules`: Rules defining the method of traffic balancing<br/>- `vms`: Instances to be the target group for ALB<br/>- `vpc`: The VPC in which the load balancer is to be run<br/>- `subnet_group`: The subnets in which the Load Balancer is to be run<br/>- `security_gropus`: Security Groups to be associated with the ALB<pre></pre> | <pre>map(object({<br/>    name = optional(string)<br/>    rules = map(object({<br/>      protocol              = optional(string, "HTTP")<br/>      port                  = optional(number, 80)<br/>      health_check_port     = optional(string, "80")<br/>      health_check_matcher  = optional(string, "200")<br/>      health_check_path     = optional(string, "/")<br/>      health_check_interval = optional(number, 10)<br/>      listener_rules = map(object({<br/>        target_protocol = string<br/>        target_port     = number<br/>        path_pattern    = list(string)<br/>      }))<br/>    }))<br/>    vms             = list(string)<br/>    vpc             = string<br/>    subnet_group    = string<br/>    security_groups = string<br/>  }))</pre> | `{}` | no |
| <a name="input_spoke_vms"></a> [spoke\_vms](#input\_spoke\_vms) | A map defining VMs in spoke VPCs.<br/><br/>Following properties are available:<br/>- `az`: name of the Availability Zone<br/>- `vpc`: name of the VPC (needs to be one of the keys in map `vpcs`)<br/>- `subnet_group`: key of the subnet\_group<br/>- `security_group`: security group assigned to ENI used by VM<br/>- `type`: EC2 VM type<br/><br/>Example:<pre>spoke_vms = {<br/>  "app1_vm01" = {<br/>    az             = "eu-central-1a"<br/>    vpc            = "app1_vpc"<br/>    subnet_group         = "app1_vm"<br/>    security_group = "app1_vm"<br/>    type           = "t3.micro"<br/>  }<br/>}</pre> | <pre>map(object({<br/>    az             = string<br/>    vpc            = string<br/>    subnet_group   = string<br/>    security_group = string<br/>    type           = optional(string, "t3.micro")<br/>  }))</pre> | `{}` | no |
| <a name="input_ssh_key_name"></a> [ssh\_key\_name](#input\_ssh\_key\_name) | Name of the SSH key pair existing in AWS key pairs and used to authenticate to VM-Series or test boxes | `string` | n/a | yes |
| <a name="input_vpcs"></a> [vpcs](#input\_vpcs) | A map defining VPCs with security groups and subnets.<br/><br/>Following properties are available:<br/>- `name`: VPC name<br/>- `cidr`: CIDR for VPC<br/>- `security_groups`: map of security groups<br/>- `subnets`: map of subnets with properties:<br/>    - `az`: availability zone<br/>    - `subnet_group`: identity of the same purpose subnets group such as management<br/>- `routes`: map of routes with properties:<br/>    - `vpc`: key of the VPC<br/>    - `subnet_group`: key of the subnet group<br/>    - `next_hop_key`: must match keys use to create TGW attachment, IGW, GWLB endpoint or other resources<br/>    - `next_hop_type`: internet\_gateway, nat\_gateway, transit\_gateway\_attachment or gwlbe\_endpoint<br/><br/>Example:<pre>vpcs = {<br/>  example_vpc = {<br/>    name = "example-spoke-vpc"<br/>    cidr = "10.104.0.0/16"<br/>    nacls = {<br/>      trusted_path_monitoring = {<br/>        name               = "trusted-path-monitoring"<br/>        rules = {<br/>          allow_inbound = {<br/>            rule_number = 300<br/>            egress      = false<br/>            protocol    = "-1"<br/>            rule_action = "allow"<br/>            cidr_block  = "0.0.0.0/0"<br/>            from_port   = null<br/>            to_port     = null<br/>          }<br/>        }<br/>      }<br/>    }<br/>    security_groups = {<br/>      example_vm = {<br/>        name = "example_vm"<br/>        rules = {<br/>          all_outbound = {<br/>            description = "Permit All traffic outbound"<br/>            type        = "egress", from_port = "0", to_port = "0", protocol = "-1"<br/>            cidr_blocks = ["0.0.0.0/0"]<br/>          }<br/>        }<br/>      }<br/>    }<br/>    subnets = {<br/>      "10.104.0.0/24"   = { az = "eu-central-1a", subnet_group = "vm", nacl = null }<br/>      "10.104.128.0/24" = { az = "eu-central-1b", subnet_group = "vm", nacl = null }<br/>    }<br/>    routes = {<br/>      vm_default = {<br/>        vpc           = "app1_vpc"<br/>        subnet_group        = "app1_vm"<br/>        to_cidr       = "0.0.0.0/0"<br/>        next_hop_key  = "app1"<br/>        next_hop_type = "transit_gateway_attachment"<br/>      }<br/>    }<br/>  }<br/>}</pre> | <pre>map(object({<br/>    name                             = string<br/>    create_vpc                       = optional(bool, true)<br/>    cidr                             = string<br/>    secondary_cidr_blocks            = optional(list(string), [])<br/>    assign_generated_ipv6_cidr_block = optional(bool)<br/>    use_internet_gateway             = optional(bool, false)<br/>    name_internet_gateway            = optional(string)<br/>    create_internet_gateway          = optional(bool, true)<br/>    route_table_internet_gateway     = optional(string)<br/>    create_vpn_gateway               = optional(bool, false)<br/>    vpn_gateway_amazon_side_asn      = optional(string)<br/>    name_vpn_gateway                 = optional(string)<br/>    route_table_vpn_gateway          = optional(string)<br/>    enable_dns_hostnames             = optional(bool, true)<br/>    enable_dns_support               = optional(bool, true)<br/>    instance_tenancy                 = optional(string, "default")<br/>    nacls = optional(map(object({<br/>      name = string<br/>      rules = map(object({<br/>        rule_number = number<br/>        egress      = bool<br/>        protocol    = string<br/>        rule_action = string<br/>        cidr_block  = string<br/>        from_port   = optional(number)<br/>        to_port     = optional(number)<br/>      }))<br/>    })), {})<br/>    security_groups = optional(map(object({<br/>      name = string<br/>      rules = map(object({<br/>        description            = optional(string)<br/>        type                   = string<br/>        cidr_blocks            = optional(list(string))<br/>        ipv6_cidr_blocks       = optional(list(string))<br/>        from_port              = string<br/>        to_port                = string<br/>        protocol               = string<br/>        prefix_list_ids        = optional(list(string))<br/>        source_security_groups = optional(list(string))<br/>        self                   = optional(bool)<br/>      }))<br/>    })), {})<br/>    subnets = optional(map(object({<br/>      name                    = optional(string, "")<br/>      az                      = string<br/>      subnet_group            = string<br/>      nacl                    = optional(string)<br/>      create_subnet           = optional(bool, true)<br/>      create_route_table      = optional(bool, true)<br/>      existing_route_table_id = optional(string)<br/>      route_table_name        = optional(string)<br/>      associate_route_table   = optional(bool, true)<br/>      local_tags              = optional(map(string), {})<br/>      map_public_ip_on_launch = optional(bool, false)<br/>    })), {})<br/>    routes = optional(map(object({<br/>      vpc                    = string<br/>      subnet_group           = string<br/>      to_cidr                = string<br/>      next_hop_key           = string<br/>      next_hop_type          = string<br/>      destination_type       = optional(string, "ipv4")<br/>      managed_prefix_list_id = optional(string)<br/>    })), {})<br/>    create_dhcp_options = optional(bool, false)<br/>    domain_name         = optional(string)<br/>    domain_name_servers = optional(list(string))<br/>    ntp_servers         = optional(list(string))<br/>    vpc_tags            = optional(map(string), {})<br/>  }))</pre> | `{}` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_load_balancers"></a> [application\_load\_balancers](#output\_application\_load\_balancers) | FQDNs of Application Load Balancers |
| <a name="output_cloudngfws"></a> [cloudngfws](#output\_cloudngfws) | Cloud NGFW service name |
<!-- END_TF_DOCS -->
