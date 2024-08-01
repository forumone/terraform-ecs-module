data "aws_iam_policy_document" "automation_ec2_assume" {
  version = "2012-10-17"

  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "automation_ec2" {
  name = "${var.name}-EC2-automation"

  assume_role_policy = data.aws_iam_policy_document.automation_ec2_assume.json

  tags = local.tags
}

resource "aws_iam_instance_profile" "automation_ec2" {
  name = aws_iam_role.automation_ec2.name
  role = aws_iam_role.automation_ec2.name
}

data "aws_iam_policy_document" "automation_ec2_s3" {
  version = "2012-10-17"

  statement {
    sid       = "ReadWriteObjects"
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject"]
    resources = ["${var.automation.transfer_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "automation_ec2_s3" {
  name        = "${var.name}-automation-ec2-S3"
  description = "Allows automated EC2 instances to use the transfer bucket"

  policy = data.aws_iam_policy_document.automation_ec2_s3.json
}

resource "aws_iam_role_policy_attachment" "automation_ec2_s3" {
  role = aws_iam_role.automation_ec2.name

  policy_arn = aws_iam_policy.automation_ec2_s3.arn
}

data "aws_iam_policy_document" "automation_ec2_efs" {
  version = "2012-10-17"

  statement {
    sid    = "readWriteRoot"
    effect = "Allow"

    # Grant automated instances root mount access. This is less damaging than it
    # seems since the access points will perform UID/GID remapping
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientRootAccess"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "automation_ec2_efs" {
  name        = "${var.name}-automation-ec2-EFS"
  description = "Grants EFS mount permission to automated EC2 instances"

  policy = data.aws_iam_policy_document.automation_ec2_efs.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "automation_ec2_efs" {
  role       = aws_iam_role.automation.name
  policy_arn = aws_iam_policy.automation_ec2_efs.arn
}

resource "aws_iam_role_policy_attachment" "automation_ec2_secrets_read_only" {
  role = aws_iam_role.automation_ec2.name

  policy_arn = aws_iam_policy.secrets_manager_read_only.arn
}

resource "aws_iam_role_policy_attachment" "automation_ec2_parameter_store" {
  role = aws_iam_role.automation_ec2.name

  policy_arn = aws_iam_policy.parameter_store_read_only.arn
}
