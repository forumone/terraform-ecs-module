# Traefik routing from behind an ALB
module "traefik_alb" {
  source = "./traefik-alb"

  ecs_cluster_name = module.ecs.cluster_name

  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets

  alb_arn               = aws_lb.alb.arn
  alb_security_group_id = aws_security_group.alb.id

  acm_default_cert_arn = module.acm.acm_certificate_arn
  acm_extra_cert_arns  = var.acm.certificates

  image_repository = var.traefik.repository
  image_tag        = var.traefik.tag

  traefik_log_level = var.traefik.log_level

  configuration_file = var.traefik.config_file

  autoscaling_min = var.traefik.min_capacity
  autoscaling_max = var.traefik.max_capacity

  cloudwatch_log_retention = var.logs.retention

  tags = local.tags
}
