# Target group and listeners: HTTP

resource "aws_lb_target_group" "traefik_http" {
  name = "${var.ecs_cluster_name}-traefik-http"

  port              = var.http_port
  protocol          = "TCP"
  target_type       = "ip"
  proxy_protocol_v2 = true
  vpc_id            = var.vpc_id

  health_check {
    enabled  = true
    interval = 10
    port     = var.http_port
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "traefik_http" {
  load_balancer_arn = var.nlb_arn
  port              = 80
  protocol          = "TCP"

  default_action {
    target_group_arn = aws_lb_target_group.traefik_http.id
    type             = "forward"
  }
}

# Target group and listeners: HTTPS

resource "aws_lb_target_group" "traefik_https" {
  name = "${var.ecs_cluster_name}-traefik-https"

  port              = var.https_port
  protocol          = "TCP"
  target_type       = "ip"
  proxy_protocol_v2 = true
  vpc_id            = var.vpc_id

  health_check {
    enabled  = true
    interval = 10
    port     = var.https_port
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "traefik_https" {
  load_balancer_arn = var.nlb_arn
  port              = 443
  protocol          = "TLS"
  ssl_policy        = var.tls_policy
  certificate_arn   = var.acm_default_cert_arn

  default_action {
    target_group_arn = aws_lb_target_group.traefik_https.id
    type             = "forward"
  }
}

resource "aws_lb_listener_certificate" "traefik_https" {
  for_each = toset(var.acm_extra_cert_arns)

  listener_arn    = aws_lb_listener.traefik_https.arn
  certificate_arn = each.key
}
