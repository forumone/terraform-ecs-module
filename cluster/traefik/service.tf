# Create ECS Service
resource "aws_ecs_service" "traefik" {
  name            = "${var.ecs_cluster_name}-traefik"
  cluster         = var.ecs_cluster_name
  task_definition = aws_ecs_task_definition.traefik.arn
  launch_type     = "FARGATE"

  desired_count = var.autoscaling_min

  load_balancer {
    target_group_arn = aws_lb_target_group.traefik_http.id
    container_name   = "traefik"
    container_port   = var.http_port
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.traefik_https.id
    container_name   = "traefik"
    container_port   = var.https_port
  }

  network_configuration {
    subnets         = var.private_subnets_ids
    security_groups = [aws_security_group.traefik.id]
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

# Create an autoscaling target for the Traefik service
resource "aws_appautoscaling_target" "traefik" {
  # Tell autoscaling which AWS service resource this target is for.
  resource_id        = "service/${var.ecs_cluster_name}/${aws_ecs_service.traefik.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  min_capacity = var.autoscaling_min
  max_capacity = var.autoscaling_max
}

# Define a CPU-based scaling policy. Autoscaling will attempt to maintain around 30% CPU
# utilization for the Traefik service.
resource "aws_appautoscaling_policy" "traefik" {
  name        = "${var.ecs_cluster_name}-traefik-autoscaling"
  policy_type = "TargetTrackingScaling"

  # Apply this policy to the traefik autoscaling target
  resource_id        = aws_appautoscaling_target.traefik.id
  scalable_dimension = aws_appautoscaling_target.traefik.scalable_dimension
  service_namespace  = aws_appautoscaling_target.traefik.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 30

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}
