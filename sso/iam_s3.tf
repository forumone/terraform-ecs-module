data "aws_iam_policy_document" "s3_access" {
  version = "2012-10-17"

  statement {
    sid       = "listBuckets"
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  # Section: read/write access to the environment files bucket(s), if any are provided
  dynamic "statement" {
    for_each = length(var.env_bucket_arns) == 0 ? toset([]) : toset([""])

    content {
      sid       = "listEnvFiles"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = var.env_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.env_bucket_arns) == 0 ? toset([]) : toset([""])

    content {
      sid       = "readWriteEnvFiles"
      effect    = "Allow"
      actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      resources = formatlist("%s/*", var.env_bucket_arns)
    }
  }

  dynamic "statement" {
    for_each = length(var.backup_bucket_arns) == 0 ? toset([]) : toset([""])

    content {
      sid       = "listBackups"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = var.backup_bucket_arns
    }
  }

  dynamic "statement" {
    for_each = length(var.backup_bucket_arns) == 0 ? toset([]) : toset([""])

    content {
      sid       = "readBackups"
      effect    = "Allow"
      actions   = ["s3:GetObject"]
      resources = formatlist("%s/*", var.backup_bucket_arns)
    }
  }
}

resource "aws_iam_policy" "s3_access" {
  name_prefix = "SSO-s3-access-"

  policy = data.aws_iam_policy_document.s3_access.json
}
