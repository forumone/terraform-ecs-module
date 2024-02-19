# On-site database backups
module "s3_backups" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0.1"

  bucket_prefix = "${var.name}-backups-"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  object_ownership        = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Expire entries on a rotating basis
  lifecycle_rule = [
    {
      id      = "expire-outdated"
      enabled = true

      expiration = [
        { days = var.backups.retention }
      ]
    }
  ]

  tags = var.tags
}

# Env file storage for ECS tasks
module "s3_env" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0.1 "

  bucket_prefix = "${var.name}-env-files-"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  object_ownership        = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Versioning for DR
  versioning = {
    enabled = true
  }

  tags = var.tags
}
