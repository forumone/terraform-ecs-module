output "security_groups" {
  description = "Map of custom security groups created for applications"

  value = {
    preprod = module.preprod.security_groups
  }
}

output "iam_role_arns" {
  description = "Map of custom IAM role ARNs created for applications"

  value = {
    preprod = module.preprod.iam_role_arns
  }
}

output "iam_role_names" {
  description = "Map of custom IAM role names created for applications"

  value = {
    preprod = module.preprod.iam_role_names
  }
}

output "s3_bucket_arns" {
  description = "Map of custom S3 bucket ARNs created for applications"

  value = {
    preprod = module.preprod.s3_bucket_arns
  }
}

output "s3_bucket_names" {
  description = "Map of custom S3 bucket names created for applications"

  value = {
    preprod = module.preprod.s3_bucket_names
  }
}

output "s3_bucket_policies" {
  description = "Map of custom S3 IAM policies created for applications"

  value = {
    preprod = module.preprod.s3_bucket_policies
  }
}

output "buildkite_builder" {
  description = "Map of ARNs of the Buildkite Docker builder role for each cluster"

  value = {
    preprod = module.preprod.buildkite_builder
  }
}

output "buildkite_deployer" {
  description = "Map of ARNs of the Buildkite deployer role for each cluster"

  value = {
    preprod = module.preprod.buildkite_deployer
  }
}
