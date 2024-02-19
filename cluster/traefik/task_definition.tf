resource "aws_ecs_task_definition" "traefik" {
  family = "${var.ecs_cluster_name}-traefik"

  task_role_arn            = aws_iam_role.traefik_task.arn
  execution_role_arn       = aws_iam_role.traefik_exec.arn
  requires_compatibilities = ["FARGATE"]

  cpu          = var.task_cpu
  memory       = var.task_memory
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name  = "startup"
      image = "public.ecr.aws/aws-cli/aws-cli:latest"

      # This is a non-essential container (it's only for startup)
      essential = false

      entryPoint = [
        "/bin/bash",
        "-ec",
        var.configuration_file == null ? "echo 'No configuration to download.'" : (
          <<-EOF
            aws s3 --only-show-errors cp s3://${module.s3_traefik.s3_bucket_id}/configuration.yaml /mnt/configuration/configuration.yaml
            echo 'Downloaded configuration.'
          EOF
        )
      ]

      environment = [
        {
          # Trick ECS into updating the task definition whenever the ETag of the configuration file changes
          name  = "_FORCE_TASK_REFRESH",
          value = try(aws_s3_object.traefik_configuration[0].etag, "0")
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "configuration"
          containerPath = "/mnt/configuration"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.traefik.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "startup"
        }
      }
    },
    {
      name  = "traefik"
      image = "${var.image_repository}:${var.image_tag}"

      entryPoint = ["traefik"]

      command = [
        # Log in JSON format for structured CloudWatch ingestion
        "--log.format=json",

        # Enable or disable access logs per the variable
        "--accesslog=${var.traefik_access_logs}",

        # Tell Traefik which region it's in
        "--providers.ecs.region=${data.aws_region.current.name}",

        # Force discovery only for this cluster
        "--providers.ecs.autoDiscoverClusters=false",
        "--providers.ecs.clusters=${var.ecs_cluster_name}",

        # Don't make services accessible by default
        "--providers.ecs.exposedByDefault=false",

        # Watch the /mnt/configuration directory for configuration; this always
        # works because an empty directory won't make Traefik do much extra
        # work.
        "--providers.file.directory=/mnt/configuration",

        # Set the log level
        "--log.level=${var.traefik_log_level}",

        # Listen for HTTP traffic, but redirect all requests to HTTPS
        "--entryPoints.web.address=:${var.http_port}",
        "--entryPoints.web.proxyProtocol=true",
        "--entryPoints.web.proxyProtocol.trustedIPs=${join(",", var.public_subnets_ipv4)}",
        "--entryPoints.web.http.redirections.entryPoint.to=websecure",
        "--entrypoints.web.http.redirections.entryPoint.scheme=https",

        # Listen for (decrypted) HTTPS traffic
        "--entryPoints.websecure.address=:${var.https_port}",
        "--entryPoints.websecure.proxyProtocol=true",
        "--entryPoints.websecure.proxyProtocol.trustedIPs=${join(",", var.public_subnets_ipv4)}"
      ]

      mountPoints = [
        {
          sourceVolume  = "configuration"
          containerPath = "/mnt/configuration"
          readOnly      = true
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"

        options = {
          awslogs-group         = aws_cloudwatch_log_group.traefik.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "traefik"
        }
      }

      dependsOn = [
        {
          # Force ECS to wait for the configuration to be downloaded into the
          # shared volume before doing anything (if there's no configuration to
          # download, the startup container will exit immediately).
          containerName = "startup"
          condition     = "COMPLETE"
        }
      ]

      portMappings = [
        {
          containerPort = var.http_port
          hostPort      = var.http_port
        },
        {
          containerPort = var.https_port
          hostPort      = var.https_port
        }
      ]
    }
  ])

  volume {
    # Allocate an empty directory to share the configuration file between
    # Traefik and the AWS CLI startup container.
    name = "configuration"
  }
}
