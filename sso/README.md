<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.7.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.37 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 5.37 |
| <a name="provider_aws.main"></a> [aws.main](#provider\_aws.main) | ~> 5.37 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.ecs_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.ecs_pass_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_ssoadmin_account_assignment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_account_assignment) | resource |
| [aws_ssoadmin_customer_managed_policy_attachment.ecs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_customer_managed_policy_attachment) | resource |
| [aws_ssoadmin_customer_managed_policy_attachment.iam](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_customer_managed_policy_attachment) | resource |
| [aws_ssoadmin_customer_managed_policy_attachment.s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_customer_managed_policy_attachment) | resource |
| [aws_ssoadmin_customer_managed_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_customer_managed_policy_attachment) | resource |
| [aws_ssoadmin_managed_policy_attachment.cloudwatch_read_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_managed_policy_attachment) | resource |
| [aws_ssoadmin_managed_policy_attachment.ecr_read_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_managed_policy_attachment) | resource |
| [aws_ssoadmin_managed_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_managed_policy_attachment) | resource |
| [aws_ssoadmin_permission_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set) | resource |
| [aws_ssoadmin_permission_set_inline_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssoadmin_permission_set_inline_policy) | resource |
| [aws_iam_policy_document.ecs_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_pass_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_identitystore_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/identitystore_group) | data source |
| [aws_ssoadmin_instances.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssoadmin_instances) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_okta_group_name"></a> [okta\_group\_name](#input\_okta\_group\_name) | Name of the group (in Okta) of users who can assume this role | `string` | n/a | yes |
| <a name="input_permission_set_name"></a> [permission\_set\_name](#input\_permission\_set\_name) | Name of the permission set (visible in the AWS SSO console) | `string` | n/a | yes |
| <a name="input_target_account"></a> [target\_account](#input\_target\_account) | Account to which this permission set applies | `string` | n/a | yes |
| <a name="input_aws_managed_policies"></a> [aws\_managed\_policies](#input\_aws\_managed\_policies) | Additional AWS-managed policies to add to this permission set | `list(string)` | `[]` | no |
| <a name="input_backup_bucket_arns"></a> [backup\_bucket\_arns](#input\_backup\_bucket\_arns) | ARN(s) of the S3 bucket(s) in which backups are stored | `list(string)` | `[]` | no |
| <a name="input_custom_managed_policies"></a> [custom\_managed\_policies](#input\_custom\_managed\_policies) | Names (not ARNs) of custom policies to add to this permission set | `list(string)` | `[]` | no |
| <a name="input_ecs_cluster_arns"></a> [ecs\_cluster\_arns](#input\_ecs\_cluster\_arns) | ARN(s) of the ECS clusters | `list(string)` | `[]` | no |
| <a name="input_env_bucket_arns"></a> [env\_bucket\_arns](#input\_env\_bucket\_arns) | ARN(s) of the S3 bucket(s) in which environment files are stored | `list(string)` | `[]` | no |
| <a name="input_inline_policy"></a> [inline\_policy](#input\_inline\_policy) | Inline policy to add to this permission set | `string` | `""` | no |
| <a name="input_permission_set_description"></a> [permission\_set\_description](#input\_permission\_set\_description) | Description for the permission set | `string` | `"Grants access to ECS resources"` | no |
| <a name="input_session_duration"></a> [session\_duration](#input\_session\_duration) | Maximum length of a session | `string` | `"PT8H"` | no |
| <a name="input_task_role_arns"></a> [task\_role\_arns](#input\_task\_role\_arns) | ARN(s) of task roles for this cluster | `list(string)` | `[]` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->