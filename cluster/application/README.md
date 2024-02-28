<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.37 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.37 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_efs"></a> [efs](#module\_efs) | terraform-aws-modules/efs/aws | 1.4.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecr_lifecycle_policy.repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_lifecycle_policy) | resource |
| [aws_ecr_repository.repository](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecr_repository) | resource |
| [aws_iam_policy.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_s3_bucket.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_security_group.custom](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_service_discovery_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/service_discovery_service) | resource |
| [aws_ssm_parameter.efs_ap_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.efs_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.iam_role_arn](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.s3_bucket_domain](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.s3_bucket_name](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_ssm_parameter.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_iam_policy_document.ecs_tasks_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application"></a> [application](#input\_application) | Object defining application configuration | <pre>object({<br>    name           = string<br>    environments   = map(list(string))<br>    containers     = list(string)<br>    roles          = optional(list(string), [])<br>    buckets        = optional(list(string), [])<br>    services       = optional(list(string), [])<br>    logGroups      = optional(list(string), [])<br>    accessPoints   = optional(list(string), [])<br>    securityGroups = optional(list(string), [])<br>  })</pre> | n/a | yes |
| <a name="input_backup_retention"></a> [backup\_retention](#input\_backup\_retention) | Retention period for backed-up objects (e.g., noncurrent S3 versions) | `number` | n/a | yes |
| <a name="input_cloudmap_namespace"></a> [cloudmap\_namespace](#input\_cloudmap\_namespace) | AWS Cloud Map namespace | `string` | n/a | yes |
| <a name="input_cloudwatch_retention"></a> [cloudwatch\_retention](#input\_cloudwatch\_retention) | Retention period for Cloudwatch logs | `number` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the ECS cluster | `string` | n/a | yes |
| <a name="input_efs_security_group"></a> [efs\_security\_group](#input\_efs\_security\_group) | Security group ID for EFS file systems | `string` | n/a | yes |
| <a name="input_vpc_availability_zones"></a> [vpc\_availability\_zones](#input\_vpc\_availability\_zones) | The VPC's availability zones | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC in which resources are created | `string` | n/a | yes |
| <a name="input_vpc_private_subnets"></a> [vpc\_private\_subnets](#input\_vpc\_private\_subnets) | The VPC's private subnets | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all created resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_efs_filesystem"></a> [efs\_filesystem](#output\_efs\_filesystem) | ARN of the EFS file system, if one was created |
| <a name="output_iam_role_arns"></a> [iam\_role\_arns](#output\_iam\_role\_arns) | Map of role nicknames to ARNs |
| <a name="output_iam_role_names"></a> [iam\_role\_names](#output\_iam\_role\_names) | Map of role nicknames to full names |
| <a name="output_s3_bucket_arns"></a> [s3\_bucket\_arns](#output\_s3\_bucket\_arns) | Map of bucket nicknames to ARNs |
| <a name="output_s3_bucket_names"></a> [s3\_bucket\_names](#output\_s3\_bucket\_names) | Map of bucket nicknames to to full names |
| <a name="output_s3_bucket_policies"></a> [s3\_bucket\_policies](#output\_s3\_bucket\_policies) | Map of bucket nicknames to read/write access policies |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | Map of custom security group names to IDs |
<!-- END_TF_DOCS -->