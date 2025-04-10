# Base PassRole permissions for anything interacting with the cluster
data "aws_iam_policy_document" "ecs_pass_role" {
  version = "2012-10-17"

  statement {
    sid     = "passRole"
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = concat(
      # Default task and execution roles
      [aws_iam_role.ecs_default_exec.arn, aws_iam_role.ecs_default_task.arn],

      # Custom roles created for applications
      flatten([
        for _, application in module.application :
        values(application.iam_role_arns)
      ])
    )
  }
}

resource "aws_iam_policy" "ecs_pass_role" {
  name        = "${var.name}-ECSPassRole"
  description = "Grants permission to use the ECS IAM task roles for the ${var.name} cluster"
  policy      = data.aws_iam_policy_document.ecs_pass_role.json

  tags = local.tags
}

# Automation access permissions; granted to Buildkite and exported to allow automated
locals {
  automation_documents = [
    aws_ssm_document.files_export,
    aws_ssm_document.files_import,
    aws_ssm_document.mysql_export,
    aws_ssm_document.mysql_import,
  ]
}

# Access to automation
data "aws_iam_policy_document" "automation_access" {
  version = "2012-10-17"

  statement {
    sid     = "startAutomation"
    effect  = "Allow"
    actions = ["ssm:StartAutomationExecution"]

    # For some reason, the ssm:StartAutomationExecution action expects different
    # ARNs for documents than Terraform gives us when a document is created. The
    # replace() call below manually adjusts the ARNs of the documents to be in
    # the format that the API permission expects.
    resources = [
      for doc in local.automation_documents :
      replace(doc.arn, "document/", "automation-definition/")
    ]
  }

  # Grant users permission to view automation executions
  statement {
    sid       = "executionReadAccess"
    effect    = "Allow"
    actions   = ["ssm:GetAutomationExecution", "ssm:GetParameters"]
    resources = ["*"]
  }

  # Allow users permission to pass the automation role
  statement {
    sid       = "passAutomationRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.automation.arn]
  }
}

resource "aws_iam_policy" "automation_access" {
  name        = "${var.name}-AutomationAccess"
  description = "Grants deployment tooling access to Systems Manager automation"

  policy = data.aws_iam_policy_document.automation_access.json

  tags = local.tags
}
