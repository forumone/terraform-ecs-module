resource "aws_iam_role" "backups_exec" {
  name        = "${var.name}-BackupsExecution"
  description = "Role to execute the backups tasks"

  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy_attachment" "backups_exec" {
  role       = aws_iam_role.backups_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "backups_credentials" {
  version = "2012-10-17"

  statement {
    sid     = "getSSHKey"
    effect  = "Allow"
    actions = ["secretsmanager:GetSecretValue"]

    resources = concat(
      [aws_secretsmanager_secret.backups.arn],
      aws_secretsmanager_secret.mysql_root_credentials[*].arn,
      aws_secretsmanager_secret.postgresql_root_credentials[*].arn,
    )
  }
}

resource "aws_iam_policy" "backups_credentials" {
  name        = "${var.name}-BackupsCredentialsAccess"
  description = "Grants backups tasks access to their SSH key"

  policy = data.aws_iam_policy_document.backups_credentials.json
}

resource "aws_iam_role_policy_attachment" "backups_credentials" {
  role       = aws_iam_role.backups_exec.name
  policy_arn = aws_iam_policy.backups_credentials.arn
}

resource "aws_iam_role" "backups_task" {
  name        = "${var.name}-BackupsTask"
  description = "Role for the backups tasks"

  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

data "aws_iam_policy_document" "backups_s3" {
  version = "2012-10-17"

  statement {
    sid       = "pushFiles"
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${module.s3_backups.s3_bucket_arn}/*"]
  }
}

resource "aws_iam_policy" "backups_s3" {
  name        = "${var.name}-BackupsS3Access"
  description = "Grants permission to push backup objects to S3"

  policy = data.aws_iam_policy_document.backups_s3.json
}

resource "aws_iam_role_policy_attachment" "backups_s3" {
  role       = aws_iam_role.backups_task.name
  policy_arn = aws_iam_policy.backups_s3.arn
}
