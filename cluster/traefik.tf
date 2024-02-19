module "traefik" {
  source = "./traefik"

  ecs_cluster_name = module.ecs.cluster_name

  vpc_id              = module.vpc.vpc_id
  private_subnets_ids = module.vpc.private_subnets
  public_subnets_ipv4 = module.vpc.public_subnets_cidr_blocks
  public_subnets_ipv6 = module.vpc.public_subnets_ipv6_cidr_blocks

  nlb_arn              = aws_lb.nlb.arn
  acm_default_cert_arn = module.acm.acm_certificate_arn
  acm_extra_cert_arns  = var.acm.certificates

  image_repository = var.traefik.repository
  image_tag        = var.traefik.tag

  traefik_log_level = var.traefik.log_level

  configuration_file = var.traefik.config_file

  autoscaling_min = var.traefik.min_capacity
  autoscaling_max = var.traefik.max_capacity

  cloudwatch_log_retention = var.logs.retention
}
