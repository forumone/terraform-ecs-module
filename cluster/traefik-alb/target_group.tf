# Listener: HTTP (redirects to HTTPS)

resource "aws_lb_listener" "traefik_http" {
  load_balancer_arn = var.alb_arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Target group and listeners: HTTPS

resource "aws_lb_listener" "traefik_https" {
  load_balancer_arn = var.alb_arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.tls_policy
  certificate_arn   = var.acm_default_cert_arn

  default_action {
    target_group_arn = aws_lb_target_group.traefik_http.id
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "traefik_https" {
  for_each = toset(var.acm_extra_cert_arns)

  listener_arn    = aws_lb_listener.traefik_https.arn
  certificate_arn = each.key
}

resource "aws_lb_target_group" "traefik_http" {
  name = "${var.ecs_cluster_name}-traefik-alb"

  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  # Hit the built-in /ping endpoint for ALB health checks
  health_check {
    enabled  = true
    interval = 10
    port     = 8080
    path     = "/ping"
    protocol = "HTTP"
  }
}
