locals {
  # Fetch all the filesystems from each application module
  backup_file_systems = [
    for application in var.applications :
    application.name
    if length(coalesce(application.accessPoints, [])) != 0
  ]
}

resource "aws_ecs_task_definition" "backup_files" {
  for_each = toset(local.backup_file_systems)

  family = "${var.name}-backup-${each.key}-files"

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

      entryPoint = ["/usr/local/bin/files-nightly.sh"]

      environment = [
        { name = "BACKUPS_SITE", value = each.key },
        { name = "CLUSTER_NAME", value = var.name },
        { name = "SSH_USERNAME", value = var.rsync.username },
        { name = "SSH_REMOTE", value = var.rsync.hostname },
        { name = "SSH_FINGERPRINT", value = var.rsync.fingerprint },
        { name = "BACKUPS_BUCKET", value = module.s3_backups.s3_bucket_id },
      ]

      secrets = [
        { name = "SSH_PRIVATE_KEY", valueFrom = "${aws_secretsmanager_secret.backups.arn}:private_key::" },
      ]

      mountPoints = [
        {
          sourceVolume  = "files"
          containerPath = "/mnt/filesystem"

          # Don't allow the backups container to modify files in EFS
          readOnly = true
        },
        {
          sourceVolume  = "scratch"
          containerPath = "/tmp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.backup_files.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "${each.key}-files"
        }
      }
    }
  ])

  ephemeral_storage {
    # ought to be big enough for one FS
    size_in_gib = 200
  }

  volume {
    name = "files"

    efs_volume_configuration {
      file_system_id     = module.application[each.key].efs_filesystem
      transit_encryption = "ENABLED"

      authorization_config {
        iam = "ENABLED"
      }
    }
  }

  volume {
    name = "scratch"
  }

  tags = var.tags
}

resource "aws_scheduler_schedule" "backup_files" {
  for_each = toset(local.backup_file_systems)

  name       = "${var.name}-backups-${each.key}-files"
  group_name = aws_scheduler_schedule_group.backups.name

  flexible_time_window {
    mode = "FLEXIBLE"

    maximum_window_in_minutes = 60
  }

  # Schedule: nightly at midnight Eastern, flexibly over an hour
  schedule_expression          = "cron(0 0 * * ? *)"
  schedule_expression_timezone = "America/New_York"

  target {
    role_arn = aws_iam_role.events_backups.arn

    arn = module.ecs.cluster_arn

    ecs_parameters {
      launch_type = "FARGATE"

      task_count          = 1
      task_definition_arn = aws_ecs_task_definition.backup_files[each.key].arn

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
