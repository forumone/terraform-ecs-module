resource "tls_private_key" "backups" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "aws_secretsmanager_secret" "backups" {
  name        = "/${var.name}/backups/credentials"
  description = "SSH public and private key for backups from this cluster"

  recovery_window_in_days = 0

  tags = merge(var.tags, {
    "f1-internal" = "true"
  })
}

resource "aws_secretsmanager_secret_version" "backups" {
  secret_id = aws_secretsmanager_secret.backups.id

  secret_string = jsonencode({
    public_key  = trimspace(tls_private_key.backups.public_key_openssh)
    private_key = trimspace(tls_private_key.backups.private_key_pem)
  })
}

resource "aws_cloudwatch_log_group" "backup_database" {
  name              = "/${var.name}/backups/database"
  retention_in_days = var.logs.retention
}

resource "aws_cloudwatch_log_group" "backup_files" {
  name              = "/${var.name}/backups/files"
  retention_in_days = var.logs.retention
}

resource "aws_ecr_repository" "backups" {
  name = "${var.name}/backups"
}

resource "aws_ecr_lifecycle_policy" "backups" {
  repository = aws_ecr_repository.backups.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 24 hours"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_sqs_queue" "backups_dead_letters" {
  name = "${var.name}-BackupsDeadLetters"
}

resource "aws_scheduler_schedule_group" "backups" {
  name = "${var.name}-backups"

  tags = var.tags
}
