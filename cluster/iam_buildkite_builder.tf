# Buildkite builder role: Builds and pushes Docker images to this cluster's ECR repositories

data "aws_iam_policy_document" "buildkite_builder_assume" {
  version = "2012-10-17"

  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.buildkite.builders
    }
  }
}

resource "aws_iam_role" "buildkite_builder" {
  name               = "${var.name}-BuildkiteBuilderRole"
  assume_role_policy = data.aws_iam_policy_document.buildkite_builder_assume.json

  tags = var.tags
}

data "aws_iam_policy_document" "buildkite_ecr_push" {
  version = "2012-10-17"

  statement {
    sid       = "login"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "readWriteImages"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage"
    ]

    resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/${var.name}/*"]
  }
}

resource "aws_iam_policy" "buildkite_ecr_push" {
  name        = "${var.name}-BuildkiteBuilderECRAccess"
  description = "Grants read/write access to the ECR repositories for the ${var.name} cluster"
  policy      = data.aws_iam_policy_document.buildkite_ecr_push.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "buildkite_ecr_push" {
  role       = aws_iam_role.buildkite_builder.name
  policy_arn = aws_iam_policy.buildkite_ecr_push.arn
}
