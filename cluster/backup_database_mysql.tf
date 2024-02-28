resource "aws_ecs_task_definition" "backup_database_mysql" {
  count = var.mysql == null ? 0 : 1

  family = "${var.name}-backup-database-mysql"

  task_role_arn      = aws_iam_role.backups_task.arn
  execution_role_arn = aws_iam_role.backups_exec.arn

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = 512
  memory = 1024

  container_definitions = jsonencode([
    {
      name  = "backup"
      image = "public.ecr.aws/forumone/ecs-backups:latest"

      essential = true

      entryPoint = ["/usr/local/bin/database-nightly-mysql.sh"]

      environment = [
        { name = "CLUSTER_NAME", value = var.name },
        { name = "DATABASE_HOST", value = module.mysql[0].cluster_endpoint },
        { name = "DATABASE_PORT", value = tostring(module.mysql[0].cluster_port) },
        { name = "SSH_USERNAME", value = var.rsync.username },
        { name = "SSH_REMOTE", value = var.rsync.hostname },
        { name = "SSH_FINGERPRINT", value = var.rsync.fingerprint },
        { name = "BACKUPS_BUCKET", value = module.s3_backups.s3_bucket_id },
      ]

      secrets = [
        { name = "DATABASE_USERNAME", valueFrom = "${aws_secretsmanager_secret.mysql_root_credentials[0].arn}:username::" },
        { name = "DATABASE_PASSWORD", valueFrom = "${aws_secretsmanager_secret.mysql_root_credentials[0].arn}:password::" },
        { name = "SSH_PRIVATE_KEY", valueFrom = "${aws_secretsmanager_secret.backups.arn}:private_key::" },
      ]

      mountPoints = [
        {
          sourceVolume  = "scratch"
          containerPath = "/tmp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.backup_database.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "database"
        }
      }
    }
  ])

  volume {
    name = "scratch"
  }

  tags = var.tags
}

resource "aws_scheduler_schedule" "backup_database_mysql" {
  count = var.mysql == null ? 0 : 1

  name       = "${var.name}-backups-database-mysql"
  group_name = aws_scheduler_schedule_group.backups.name

  flexible_time_window {
    mode = "FLEXIBLE"

    # Allow about 15 minutes' worth of time slop
    maximum_window_in_minutes = 15
  }

  # Schedule: nightly at midnight Eastern
  schedule_expression          = "cron(0 0 * * ? *)"
  schedule_expression_timezone = "America/New_York"

  target {
    role_arn = aws_iam_role.events_backups.arn

    arn = module.ecs.cluster_arn

    ecs_parameters {
      launch_type = "FARGATE"

      task_count          = 1
      task_definition_arn = aws_ecs_task_definition.backup_database_mysql[0].arn

      network_configuration {
        subnets         = module.vpc.private_subnets
        security_groups = [aws_security_group.ecs.id, aws_security_group.backups.id]
      }
    }

    # Log failures to deliver in SQS
    dead_letter_config {
      arn = aws_sqs_queue.backups_dead_letters.arn
    }
  }
}
