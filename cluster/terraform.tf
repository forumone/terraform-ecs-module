module "s3_tfstate" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0.1"

  bucket_prefix = "${var.name}-tfstate-"

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

resource "aws_dynamodb_table" "terraform_locks" {
  name = "${var.name}-TerraformLocks"

  hash_key     = "LockID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  tags = var.tags
}
