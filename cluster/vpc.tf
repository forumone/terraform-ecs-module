module "vpc" {
  source                               = "terraform-aws-modules/vpc/aws"
  version                              = "~> 5.4"
  name                                 = var.name
  azs                                  = slice(data.aws_availability_zones.available.names, 0, var.vpc.az_count)
  manage_default_security_group        = true
  enable_flow_log                      = false
  create_flow_log_cloudwatch_log_group = false
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval    = 600
  default_vpc_enable_dns_hostnames     = true
  default_vpc_enable_dns_support       = true
  dhcp_options_domain_name             = "${var.name}.internal"
  dhcp_options_domain_name_servers     = ["AmazonProvidedDNS"]
  enable_dhcp_options                  = true
  enable_dns_hostnames                 = true
  enable_dns_support                   = true
  enable_nat_gateway                   = true
  single_nat_gateway                   = false
  one_nat_gateway_per_az               = true
  create_igw                           = true

  cidr                            = var.vpc.cidr
  private_subnets                 = [for i in range(var.vpc.az_count) : cidrsubnet(var.vpc.cidr, 8, i)]
  public_subnets                  = [for i in range(var.vpc.az_count) : cidrsubnet(var.vpc.cidr, 8, i + 10)]
  database_subnets                = [for i in range(var.vpc.az_count) : cidrsubnet(var.vpc.cidr, 8, i + 20)]
  elasticache_subnets             = [for i in range(var.vpc.az_count) : cidrsubnet(var.vpc.cidr, 8, i + 30)]
  create_database_subnet_group    = true
  create_elasticache_subnet_group = true

  enable_ipv6                                        = true
  private_subnet_assign_ipv6_address_on_creation     = true
  private_subnet_ipv6_prefixes                       = [for i in range(var.vpc.az_count) : i + 10]
  public_subnet_ipv6_prefixes                        = [for i in range(var.vpc.az_count) : i + 20]
  database_subnet_ipv6_prefixes                      = [for i in range(var.vpc.az_count) : i + 30]
  elasticache_subnet_ipv6_prefixes                   = [for i in range(var.vpc.az_count) : i + 40]
  database_subnet_assign_ipv6_address_on_creation    = true
  elasticache_subnet_assign_ipv6_address_on_creation = true

  private_subnet_enable_dns64     = false
  database_subnet_enable_dns64    = false
  elasticache_subnet_enable_dns64 = false
}

module "endpoints" {
  source             = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version            = "~> 5.4"
  vpc_id             = module.vpc.vpc_id
  security_group_ids = [module.vpc.default_security_group_id]

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids

      tags = { Name = "s3-vpc-endpoint" }
    }
  }
}

# Write info to paramstore
resource "aws_ssm_parameter" "private_subnets" {
  name  = "/${var.name}/vpc/private-subnets"
  type  = "StringList"
  value = join(",", module.vpc.private_subnets)
}
