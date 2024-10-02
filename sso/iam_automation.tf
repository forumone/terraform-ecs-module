locals {
  # Convert document ARNs into automation definition ARNs, as required by the StartAutomationExecution API
  automation_definition_arns = [
    for arn in var.automation_document_arns :
    replace(arn, "document/", "automation-definition/")
  ]
}

data "aws_iam_policy_document" "automation_access" {
  version = "2012-10-17"

  statement {
    sid     = "runAutomation"
    effect  = "Allow"
    actions = ["ssm:StartAutomationExecution"]

    resources = formatlist("%s:$LATEST", local.automation_definition_arns)
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
