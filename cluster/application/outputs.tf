output "security_groups" {
  description = "Map of custom security group names to IDs"

  value = {
    for key, security_group in aws_security_group.custom :
    key => security_group.id
  }
}

output "iam_role_arns" {
  description = "Map of role nicknames to ARNs"

  value = {
    for key, role in aws_iam_role.custom :
    key => role.arn
  }
}

output "iam_role_names" {
  description = "Map of role nicknames to full names"

  value = {
    for key, role in aws_iam_role.custom :
    key => role.name
  }
}

output "s3_bucket_arns" {
  description = "Map of bucket nicknames to ARNs"

  value = {
    for key, bucket in aws_s3_bucket.custom :
    key => bucket.arn
  }
}

output "s3_bucket_names" {
  description = "Map of bucket nicknames to to full names"

  value = {
    for key, bucket in aws_s3_bucket.custom :
    key => bucket.bucket
  }
}

output "s3_bucket_policies" {
  description = "Map of bucket nicknames to read/write access policies"

  value = {
    for key, policy in aws_iam_policy.s3_access :
    key => policy.arn
  }
}

output "efs_filesystem" {
  description = "ARN of the EFS file system, if one was created"

  value = try(module.efs[0].id, null)
}
