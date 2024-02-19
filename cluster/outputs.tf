output "s3_env_files" {
  description = "ARN of the S3 environment files bucket"
  value       = module.s3_env.s3_bucket_arn
}

output "s3_backups" {
  description = "ARN of the S3 backups bucket"
  value       = module.s3_backups.s3_bucket_arn
}

output "security_groups" {
  description = "Map of custom security groups created for applications"

  value = {
    for name, application in module.application :
    name => application.security_groups
    if length(application.security_groups) > 0
  }
}

output "iam_role_arns" {
  description = "Map of custom IAM role ARNs created for applications"

  value = {
    for name, application in module.application :
    name => application.iam_role_arns
    if length(application.iam_role_arns) > 0
  }
}

output "iam_role_names" {
  description = "Map of custom IAM role names created for applications"

  value = {
    for name, application in module.application :
    name => application.iam_role_names
    if length(application.iam_role_names) > 0
  }
}

output "s3_bucket_arns" {
  description = "Map of custom S3 bucket ARNs created for applications"

  value = {
    for name, application in module.application :
    name => application.s3_bucket_arns
    if length(application.s3_bucket_arns) > 0
  }
}

output "s3_bucket_names" {
  description = "Map of custom S3 bucket names created for applications"

  value = {
    for name, application in module.application :
    name => application.s3_bucket_names
    if length(application.s3_bucket_names) > 0
  }
}

output "s3_bucket_policies" {
  description = "Map of custom S3 IAM policies created for applications"

  value = {
    for name, application in module.application :
    name => application.s3_bucket_policies
    if length(application.s3_bucket_policies) > 0
  }
}

output "buildkite_builder" {
  description = "ARN of the Docker builder role for Buildkite to assume"
  value       = aws_iam_role.buildkite_builder.arn
}

output "buildkite_deployer" {
  description = "ARN of the Terraform deployment role for Buildkite to assume"
  value       = aws_iam_role.buildkite_deployer.arn
}

output "ssm_read_policy" {
  description = "Name of the Systems Manager read-only policy"
  value       = aws_iam_policy.parameter_store_read_only.name
}

output "cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = module.ecs.cluster_arn
}

output "cluster_roles" {
  description = "List of role ARNs associated with cluster tasks"

  value = concat(
    [aws_iam_role.ecs_default_exec.arn, aws_iam_role.ecs_default_task.arn],
    flatten([
      for _, application in module.application :
      values(application.iam_role_arns)
    ])
  )
}
