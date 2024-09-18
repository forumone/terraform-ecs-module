# This log bucket needs to stay until downstream users have emptied it.
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

  tags = local.tags
}
