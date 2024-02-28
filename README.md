# terraform-ecs-module
Forumone's ECS Terraform Module with Traefik and Rsync.net for offsite backups

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_buildkite_builder"></a> [buildkite\_builder](#output\_buildkite\_builder) | Map of ARNs of the Buildkite Docker builder role for each cluster |
| <a name="output_buildkite_deployer"></a> [buildkite\_deployer](#output\_buildkite\_deployer) | Map of ARNs of the Buildkite deployer role for each cluster |
| <a name="output_iam_role_arns"></a> [iam\_role\_arns](#output\_iam\_role\_arns) | Map of custom IAM role ARNs created for applications |
| <a name="output_iam_role_names"></a> [iam\_role\_names](#output\_iam\_role\_names) | Map of custom IAM role names created for applications |
| <a name="output_s3_bucket_arns"></a> [s3\_bucket\_arns](#output\_s3\_bucket\_arns) | Map of custom S3 bucket ARNs created for applications |
| <a name="output_s3_bucket_names"></a> [s3\_bucket\_names](#output\_s3\_bucket\_names) | Map of custom S3 bucket names created for applications |
| <a name="output_s3_bucket_policies"></a> [s3\_bucket\_policies](#output\_s3\_bucket\_policies) | Map of custom S3 IAM policies created for applications |
| <a name="output_security_groups"></a> [security\_groups](#output\_security\_groups) | Map of custom security groups created for applications |
<!-- END_TF_DOCS -->