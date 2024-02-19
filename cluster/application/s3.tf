locals {
  buckets = {
    for pair in setproduct(local.environments, var.application.buckets) :
    "${pair[0]}-${pair[1]}" => {
      env    = pair[0]
      bucket = pair[1]
    }
  }
}

resource "aws_s3_bucket" "custom" {
  for_each = local.buckets

  bucket_prefix = "${var.application.name}-${each.value.env}-${each.value.bucket}-"

  tags = var.tags
}

# Enable at-rest encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "custom" {
  for_each = local.buckets

  bucket = aws_s3_bucket.custom[each.key].bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "custom" {
  for_each = local.buckets

  bucket = aws_s3_bucket.custom[each.key].bucket

  versioning_configuration {
    status = "Enabled"
  }
}

# Manage lifecycle by expiring noncurrent versions
resource "aws_s3_bucket_lifecycle_configuration" "custom" {
  for_each = local.buckets

  bucket = aws_s3_bucket.custom[each.key].bucket

  # Expire abandoned multipart uploads; this wastes space in S3 without
  # corresponding to a real object. This behavior cannot be adjusted from
  # outside this module.
  rule {
    id     = "expire-multipart"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  # Expire noncurrent versions (i.e., deleted/updated objects) after our backup
  # retention period
  rule {
    id     = "expire-noncurrent"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = var.backup_retention
    }
  }
}

# Not managed here:
# * Public access blocks
# * Ownership enforcement (vs. ACLs)
# * Policies, such as those that grant public access to a subpath

# Create a policy that grants read/write access to objects and limited read access to buckets
data "aws_iam_policy_document" "s3_access" {
  for_each = local.buckets

  statement {
    sid       = "bucketReadList"
    effect    = "Allow"
    actions   = ["s3:ListBucket", "s3:ListBucketVersions", "s3:GetBucketLocation"]
    resources = [aws_s3_bucket.custom[each.key].arn]
  }

  statement {
    sid    = "objectReadWrite"
    effect = "Allow"

    actions = [
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectAcl",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]

    resources = ["${aws_s3_bucket.custom[each.key].arn}/*"]
  }
}

resource "aws_iam_policy" "s3_access" {
  for_each = local.buckets

  name   = "${var.cluster_name}-${var.application.name}-${each.value.env}-${each.value.bucket}-ObjectAccess"
  policy = data.aws_iam_policy_document.s3_access[each.key].json

  tags = var.tags
}

# Create SSM parameters for:
# 1. the bucket's name (needed for code that reads/writes to S3) and
# 2. the bucket's regional domain name (needed for server configurations that
#    proxy directly to S3)
resource "aws_ssm_parameter" "s3_bucket_name" {
  for_each = local.buckets

  name  = "${local.directory_prefix}/${each.value.env}/buckets/${each.value.bucket}/name"
  type  = "String"
  value = aws_s3_bucket.custom[each.key].bucket

  tags = var.tags
}

resource "aws_ssm_parameter" "s3_bucket_domain" {
  for_each = local.buckets

  name  = "${local.directory_prefix}/${each.value.env}/buckets/${each.value.bucket}/domain"
  type  = "String"
  value = aws_s3_bucket.custom[each.key].bucket_regional_domain_name

  tags = var.tags
}
