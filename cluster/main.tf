data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

locals {
  tags = merge(var.tags, {
    "forumone:cluster" = var.name
  })

  # Tag specification used in automation documents
  tag_list = [
    for key, value in local.tags :
    { Key = key, Value = value }
  ]
}
