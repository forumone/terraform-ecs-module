locals {
  db_create = var.mysql != null || var.postgresql != null
}

# IAM For Execution Role
data "aws_iam_policy_document" "terraform_database_credentials_access" {
  count = local.db_create ? 1 : 0

  version = "2012-10-17"

  statement {
    sid       = "read"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = concat(aws_secretsmanager_secret.mysql_root_credentials[*].arn, aws_secretsmanager_secret.postgresql_root_credentials[*].arn)
  }
}

resource "aws_iam_role" "terraform_database_exec" {
  name               = "${var.name}-TerraformDatabaseExecution"
  description        = "Role to execute the Terraform-based database initialization"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "terraform_database_exec" {
  role       = aws_iam_role.terraform_database_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_policy" "terraform_database_credentials_access" {
  count       = local.db_create ? 1 : 0
  name        = "${var.name}-TerraformDatabaseRootCredsAccess"
  description = "Allows binding the root RDS credentials to the Terraform database task"
  policy      = data.aws_iam_policy_document.terraform_database_credentials_access[0].json
}

resource "aws_iam_role_policy_attachment" "terraform_database_credentials_access" {
  count      = local.db_create ? 1 : 0
  role       = aws_iam_role.terraform_database_exec.name
  policy_arn = aws_iam_policy.terraform_database_credentials_access[0].arn
}

#IAM for Task Role
data "aws_iam_policy_document" "terraform_database_tfstate_access" {
  version = "2012-10-17"

  statement {
    sid       = "readBucket"
    effect    = "Allow"
    actions   = ["s3:Listbucket"]
    resources = [module.s3_tfstate.s3_bucket_arn]
  }

  statement {
    sid       = "readWriteState"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["${module.s3_tfstate.s3_bucket_arn}/tf_aurora_mysql.tfstate", "${module.s3_tfstate.s3_bucket_arn}/tf_aurora_postgresql.tfstate"]
  }
}

data "aws_iam_policy_document" "terraform_database_secrets_access" {
  version = "2012-10-17"

  statement {
    sid    = "readWrite"
    effect = "Allow"

    actions = [
      "secretsmanager:CreateSecret",
      "secretsmanager:DeleteSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:UpdateSecret",
      "secretsmanager:TagResource",
      "secretsmanager:UntagResource",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
      "secretsmanager:GetResourcePolicy"
    ]
    # Need to figure out the resource pattern for this
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "terraform_locks_access" {
  version = "2012-10-17"

  statement {
    sid       = "itemAccess"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.terraform_locks.arn]
  }
}

resource "aws_iam_policy" "terraform_database_tfstate_access" {
  name        = "${var.name}-TerraformDatabaseTFStateAccess"
  description = "Grants access to remote backend S3 bucket/tf_aurora_mysql.tfstate or tf_aurora_postgresql.tfstate"
  policy      = data.aws_iam_policy_document.terraform_database_tfstate_access.json
}

resource "aws_iam_policy" "terraform_locks_access" {
  name        = "${var.name}-TerraformDatabaseTFLocksAccess"
  description = "Grants access to remote backend Dynamo DB Terraform Locks Table"
  policy      = data.aws_iam_policy_document.terraform_locks_access.json
}

resource "aws_iam_role" "terraform_database_task" {
  name               = "${var.name}-TerraformDatabaseTask"
  description        = "Role for the Terraform-based database initialization process"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "terraform_database_tfstate_access" {
  role       = aws_iam_role.terraform_database_task.name
  policy_arn = aws_iam_policy.terraform_database_tfstate_access.arn
}

resource "aws_iam_role_policy_attachment" "terraform_database_locks_access" {
  role       = aws_iam_role.terraform_database_task.name
  policy_arn = aws_iam_policy.terraform_locks_access.arn
}

resource "aws_iam_policy" "terraform_database_secrets_access" {
  name        = "${var.name}-TerraformDatabaseSecretsAccess"
  description = "Grants access to the DB credentials for initialization for Databases"
  policy      = data.aws_iam_policy_document.terraform_database_secrets_access.json
}

resource "aws_iam_role_policy_attachment" "terraform_database_secrets_access" {
  role       = aws_iam_role.terraform_database_task.name
  policy_arn = aws_iam_policy.terraform_database_secrets_access.arn
}


# AWS Event Bridge IAM Role
data "aws_iam_policy_document" "aws_cloudwatch_event_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "aws_cloudwatch_event_policy" {
  count = local.db_create ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["ecs:RunTask"]
    resources = concat(aws_ecs_task_definition.terraform_mysql_database_exec[*].arn, aws_ecs_task_definition.terraform_postgresql_database_exec[*].arn)

    condition {
      test     = "ArnEquals"
      variable = "ecs:cluster"
      values   = [module.ecs.cluster_arn]
    }
  }
  statement {
    effect  = "Allow"
    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.terraform_database_task.arn,
      aws_iam_role.terraform_database_exec.arn
    ]
  }
}

resource "aws_iam_role" "db_scheduled_event_bridge" {
  name               = "${var.name}-terraform-event-bridge-run"
  assume_role_policy = data.aws_iam_policy_document.aws_cloudwatch_event_assume_role.json
}

resource "aws_iam_role_policy" "scheduled_task_cw_event_role_cloudwatch_policy" {
  count  = local.db_create ? 1 : 0
  name   = "${var.name}-terraform-event-bridge-policy"
  role   = aws_iam_role.db_scheduled_event_bridge.id
  policy = data.aws_iam_policy_document.aws_cloudwatch_event_policy[0].json
}
