module "s3_traefik" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.0.1"

  bucket_prefix = "${var.ecs_cluster_name}-traefik-"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  object_ownership = "BucketOwnerEnforced"

  attach_deny_insecure_transport_policy = true
  attach_require_latest_tls_policy      = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_object" "traefik_configuration" {
  count = var.configuration_file == null ? 0 : 1

  bucket = module.s3_traefik.s3_bucket_id
  key    = "configuration.yaml"

  content_type = "application/yaml"

  source = var.configuration_file
  etag   = filemd5(var.configuration_file)
}
