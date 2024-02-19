# Create S3 log bucket for NLB logs - use random string for unique S3 name

module "nlb_log_bucket" {
  source                        = "terraform-aws-modules/s3-bucket/aws"
  version                       = "~> 4.0.1"
  bucket_prefix                 = "${var.name}-nlb-logs-"
  acl                           = "log-delivery-write"
  force_destroy                 = true
  attach_lb_log_delivery_policy = true
  control_object_ownership      = true
  block_public_acls             = true
  block_public_policy           = true
  ignore_public_acls            = true
  restrict_public_buckets       = true
  object_ownership              = "ObjectWriter"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Expire log entries per our retention policy
  lifecycle_rule = [
    {
      id      = "expire-log-entries"
      enabled = true

      expiration = [
        { days = var.logs.retention }
      ]
    }
  ]

  tags = var.tags
}

resource "aws_lb" "nlb" {
  name                       = var.name
  enable_deletion_protection = false
  load_balancer_type         = "network"
  ip_address_type            = "dualstack"
  subnets                    = module.vpc.public_subnets

  access_logs {
    bucket  = module.nlb_log_bucket.s3_bucket_id
    prefix  = "logs"
    enabled = true
  }

  tags = var.tags
}
