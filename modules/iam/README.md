# Palo Alto Networks IAM Module for AWS

One instance of the module is designed to create one policy.
It supports policies for following use cases:
* VM-Series
* S3 based bootstrap
* Lambda
* spokes with managed AWS SSM
* custom policy

## Usage

## Reference
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0, < 2.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.17 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.17 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_s3_bucket"></a> [aws\_s3\_bucket](#input\_aws\_s3\_bucket) | Name of the s3 bucket, that is required and used for<pre>var.create_bootrap_policy</pre>. | `string` | `null` | no |
| <a name="input_create_bootrap_policy"></a> [create\_bootrap\_policy](#input\_create\_bootrap\_policy) | Create a pre-defined bootstrap policy. | `bool` | `false` | no |
| <a name="input_create_instance_profile"></a> [create\_instance\_profile](#input\_create\_instance\_profile) | Create an instance profile. | `bool` | `false` | no |
| <a name="input_create_lambda_policy"></a> [create\_lambda\_policy](#input\_create\_lambda\_policy) | Create a pre-defined lambda policies for ASG. | `bool` | `false` | no |
| <a name="input_create_role"></a> [create\_role](#input\_create\_role) | Create a dedicated role creation of pre-defined policies. | `bool` | `true` | no |
| <a name="input_create_vmseries_policy"></a> [create\_vmseries\_policy](#input\_create\_vmseries\_policy) | Create a pre-defined vmseries policy. | `bool` | `false` | no |
| <a name="input_custom_policy"></a> [custom\_policy](#input\_custom\_policy) | A custom lambda policy. Multi-statement is supported.<br>Basic example:<pre>statement1 = {<br>    sid    = "1"<br>    effect = "Allow"<br>    actions = [<br>      "logs:CreateLogGroup",<br>      "logs:CreateLogStream",<br>      "logs:PutLogEvents"<br>    ]<br>    resources = [<br>      "arn:*:logs:*:*:*"<br>    ]<br>  }<br>  statement2 = {<br>    sid    = "2"<br>    effect = "Allow"<br>    actions = [<br>      "ec2:AllocateAddress",<br>      "ec2:AssociateAddress",<br>      "ec2:AttachNetworkInterface",<br>      "ec2:CreateNetworkInterface",<br>      "ec2:CreateTags",<br>      "ec2:DescribeAddresses",<br>      "ec2:DescribeInstances",<br>      "ec2:DescribeNetworkInterfaces",<br>      "ec2:DescribeTags",<br>      "ec2:DescribeSubnets",<br>      "ec2:DeleteNetworkInterface",<br>      "ec2:DeleteTags",<br>      "ec2:DetachNetworkInterface",<br>      "ec2:DisassociateAddress",<br>      "ec2:ModifyNetworkInterfaceAttribute",<br>      "ec2:ReleaseAddress",<br>      "autoscaling:CompleteLifecycleAction",<br>      "autoscaling:DescribeAutoScalingGroups",<br>      "elasticloadbalancing:RegisterTargets",<br>      "elasticloadbalancing:DeregisterTargets"<br>    ]<br><br>    resources = ["*"]<br><br>    condition = {<br>      test     = "StringEquals"<br>      variable = "aws:ResourceTag/Owner"<br>      values   = "user1"<br>    }<br>  }</pre> | <pre>map(object({<br>    sid       = string<br>    effect    = string<br>    actions   = list(string)<br>    resources = list(string)<br>    condition = optional(object({<br>      test     = string<br>      variable = string<br>      values   = list(string)<br>    }))<br>  }))</pre> | `null` | no |
| <a name="input_delicense_ssm_param_name"></a> [delicense\_ssm\_param\_name](#input\_delicense\_ssm\_param\_name) | It is required for IAM de-licensing permission IAM settings.<br>Secure string in Parameter Store with value in below format:<pre>{"username":"ACCOUNT","password":"PASSWORD","panorama1":"IP_ADDRESS1","panorama2":"IP_ADDRESS2","license_manager":"LICENSE_MANAGER_NAME"}"</pre>the format can either be the plain name in case you store it without hierarchy or with a "/" in case you store in in a hierarchy | `string` | `null` | no |
| <a name="input_global_tags"></a> [global\_tags](#input\_global\_tags) | Global tags configured for all provisioned resources. | `map(any)` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix used in names for the resources. (IAM Role, Instance Profile) | `string` | n/a | yes |
| <a name="input_policy_arn"></a> [policy\_arn](#input\_policy\_arn) | The AWS or Customer managed policy arn. It should be used for spoke VM scenario using the AWS managed<pre>arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore</pre>policy. | `string` | `null` | no |
| <a name="input_principal_role"></a> [principal\_role](#input\_principal\_role) | The type of entity that can take actions in AWS. | `string` | `"ec2.amazonaws.com"` | no |
| <a name="input_profile_instance_name"></a> [profile\_instance\_name](#input\_profile\_instance\_name) | A profile instance name. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where SSM or CloudWatch is located. | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | A role name, required for the service. | `string` | n/a | yes |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_role"></a> [iam\_role](#output\_iam\_role) | The role used for policies. |
| <a name="output_instance_profile"></a> [instance\_profile](#output\_instance\_profile) | The instance profile created for VM. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
