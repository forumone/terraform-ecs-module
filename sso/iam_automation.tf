data "aws_iam_policy_document" "automation_access" {
  version = "2012-10-17"

  statement {
    sid       = "runAutomation"
    effect    = "Allow"
    actions   = ["ssm:StartAutomationExecution"]
    resources = var.automation_document_arns
  }

  statement {
    sid       = "getExecution"
    effect    = "Allow"
    actions   = ["ssm:GetAutomationExecution"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "automation_access" {
  name_prefix = "SSO-automation-access-"

  policy = data.aws_iam_policy_document.automation_access.json
}
