locals {
  # Create a map of access points with a unique key, with 'env' and 'ap'
  # properties:
  # * env: the name of the environment (e.g., "dev" or "www")
  # * ap: the name of the access point (e.g., "files" or "plugin-cache")
  access_points = {
    for pair in setproduct(local.environments, var.application.accessPoints) :
    "${pair[0]}-${pair[1]}" => {
      env = pair[0]
      ap  = pair[1]
    }
  }

  efs_uid = 1000
  efs_gid = 1000
}

module "efs" {
  # Create an EFS file system only if there are access points for this cluster
  count = length(local.access_points) > 0 ? 1 : 0

  source  = "terraform-aws-modules/efs/aws"
  version = "1.4.0"

  # Corresponds to the 'Name' tag in AWS
  name = "${var.cluster_name}/${var.application.name}"

  create = true

  # We don't create a custom security group for EFS, relying instead on a
  # passed-in one.
  create_security_group = false

  # Encrypt EFS at rest, and the 'attach_policy' option creates a policy that
  # denies any unencrypted connection.
  encrypted     = true
  attach_policy = true

  # Create a mount target for each subnet using the shared EFS security group.
  mount_targets = {
    for i in range(length(var.vpc_availability_zones)) :
    var.vpc_availability_zones[i] => {
      subnet_id       = var.vpc_private_subnets[i]
      security_groups = [var.efs_security_group]
    }
  }

  access_points = {
    for key, info in local.access_points :
    key => {
      # Corresponds to the 'Name' tag in AWS
      name = "${var.cluster_name}/${var.application.name}/${info.env}/${info.ap}"

      # Map all user/group requests to this predefined UID/GID.
      posix_user = {
        uid = local.efs_uid
        gid = local.efs_gid
      }

      # Auto create each directory based on environment
      root_directory = {
        path = "/${info.env}/${info.ap}"

        creation_info = {
          owner_uid   = local.efs_uid
          owner_gid   = local.efs_gid
          permissions = "755"
        }
      }

      tags = var.tags
    }
  }

  tags = var.tags
}

resource "aws_ssm_parameter" "efs_id" {
  count = length(module.efs)

  name  = "${local.directory_prefix}/efs/filesystem"
  type  = "String"
  value = module.efs[0].id

  tags = var.tags
}

resource "aws_ssm_parameter" "efs_ap_id" {
  for_each = local.access_points

  name  = "${local.directory_prefix}/${each.value.env}/access-points/${each.value.ap}"
  type  = "String"
  value = module.efs[0].access_points[each.key].id

  tags = var.tags
}
