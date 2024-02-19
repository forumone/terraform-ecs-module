module "application" {
  source = "./application"
  for_each = {
    for application in var.applications :
    application.name => application
  }

  cluster_name = var.name
  application  = each.value

  cloudwatch_retention = var.logs.retention
  backup_retention     = var.backups.retention

  cloudmap_namespace = var.dns.cloudmap ? aws_service_discovery_private_dns_namespace.private_dns[0].id : null

  efs_security_group = aws_security_group.efs.id

  vpc_id                 = module.vpc.vpc_id
  vpc_private_subnets    = module.vpc.private_subnets
  vpc_availability_zones = module.vpc.azs
}
