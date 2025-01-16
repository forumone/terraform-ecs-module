data "aws_iam_policy_document" "automation_assume" {
  statement {
    sid     = "1"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "automation" {
  name = "${var.name}-SSM-Automation"

  assume_role_policy = data.aws_iam_policy_document.automation_assume.json

  tags = local.tags
}

data "aws_iam_policy_document" "automation_ssm_ec2" {
  version = "2012-10-17"

  # Restrict AMI selection to just official AMIs
  statement {
    sid       = "RunAmazonAMIs"
    effect    = "Allow"
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:*:*:image/ami-*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:Owner"
      values   = ["amazon"]
    }
  }

  statement {
    sid       = "LaunchPrivateInstances"
    effect    = "Allow"
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:*:*:network-interface/*"]

    condition {
      test     = "BoolIfExists"
      variable = "ec2:AssociatePublicIp"
      values   = ["false"]
    }
  }

  statement {
    sid     = "RestrictNetworking"
    effect  = "Allow"
    actions = ["ec2:RunInstances"]

    resources = concat(
      # Only allow launching in these subnets
      module.vpc.private_subnet_arns,

      # Only allow these security groups
      [aws_security_group.automation_ec2.arn],
    )
  }

  statement {
    sid     = "RunInstances"
    effect  = "Allow"
    actions = ["ec2:RunInstances"]

    resources = [
      "arn:aws:ec2:*:*:instance/*",
      "arn:aws:ec2:*:*:key-pair/*",
      "arn:aws:ec2:*:*:volume/*",
    ]
  }

  # Allow tagging instances at launch
  statement {
    sid       = "TagInstances"
    effect    = "Allow"
    actions   = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["RunInstances"]
    }
  }

  # Allow mentioning the automated instances IAM role
  statement {
    sid       = "PassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.automation_ec2.arn]
  }

  # Allow fetching public AWS AMI parameters
  statement {
    sid       = "PublicParameters"
    effect    = "Allow"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = ["arn:aws:ssm:${data.aws_region.current.name}::parameter/aws/service/ami-amazon-linux-latest/*"]
  }

  statement {
    sid       = "DescribeInstances"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"]
  }

  statement {
    sid       = "DescribeInstanceStatus"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstanceStatus"]
    resources = ["*"]
  }

  statement {
    sid       = "TerminateInstances"
    effect    = "Allow"
    actions   = ["ec2:TerminateInstances"]
    resources = ["arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"]
  }

  statement {
    sid       = "SendCommand"
    effect    = "Allow"
    actions   = ["ssm:SendCommand", "ssm:DescribeInstanceInformation", "ssm:ListCommands", "ssm:ListCommandInvocations"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "automation_ssm_ec2" {
  name        = "${var.name}-automation-ssm-ec2"
  description = "Grants permission for Systems Manager to launch EC2 instances"

  policy = data.aws_iam_policy_document.automation_ssm_ec2.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "automation_ssm_ec2" {
  role = aws_iam_role.automation.name

  policy_arn = aws_iam_policy.automation_ssm_ec2.arn
}
