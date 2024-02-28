# Load the list of instance identity stores
data "aws_ssoadmin_instances" "this" {
  provider = aws.main
}

# Find the Okta group matching the given name
data "aws_identitystore_group" "this" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "DisplayName"
      attribute_value = var.okta_group_name
    }
  }
  provider = aws.main
}

# Register the permission set
resource "aws_ssoadmin_permission_set" "this" {
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]

  name             = var.permission_set_name
  description      = var.permission_set_description
  session_duration = var.session_duration
  provider         = aws.main
}

resource "aws_ssoadmin_managed_policy_attachment" "ecr_read_write" {
  instance_arn = aws_ssoadmin_permission_set.this.instance_arn

  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  provider           = aws.main
}

resource "aws_ssoadmin_managed_policy_attachment" "cloudwatch_read_only" {
  instance_arn = aws_ssoadmin_permission_set.this.instance_arn

  permission_set_arn = aws_ssoadmin_permission_set.this.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
  provider           = aws.main
}

# Attach AWS-managed policies to the permission set
resource "aws_ssoadmin_managed_policy_attachment" "this" {
  for_each = toset(var.aws_managed_policies)

  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  managed_policy_arn = each.key
  provider           = aws.main
}

resource "aws_ssoadmin_permission_set_inline_policy" "this" {
  count = var.inline_policy == "" ? 0 : 1

  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  inline_policy = var.inline_policy
  provider      = aws.main
}

# Attach custom policies to the permission set
resource "aws_ssoadmin_customer_managed_policy_attachment" "this" {
  for_each = toset(var.custom_managed_policies)

  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  customer_managed_policy_reference {
    name = each.key
    path = "/"
  }
  provider = aws.main
}

# Attach our policies to the permission set

# S3 access: grant permission to access some S3 buckets
resource "aws_ssoadmin_customer_managed_policy_attachment" "s3" {
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  customer_managed_policy_reference {
    name = aws_iam_policy.s3_access.name
    path = aws_iam_policy.s3_access.path
  }
  provider = aws.main
}

# Developers will always have some level of read-only access to ECS
resource "aws_ssoadmin_customer_managed_policy_attachment" "ecs" {
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  customer_managed_policy_reference {
    name = aws_iam_policy.ecs_access.name
    path = aws_iam_policy.ecs_access.path
  }
  provider = aws.main
}

# In order to run tasks in the cluster(s), developers will need to pass
# ECS-related roles
resource "aws_ssoadmin_customer_managed_policy_attachment" "iam" {
  instance_arn       = aws_ssoadmin_permission_set.this.instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  customer_managed_policy_reference {
    name = aws_iam_policy.ecs_pass_role.name
    path = aws_iam_policy.ecs_pass_role.path
  }
  provider = aws.main
}

# Finally, assign the permission set to this account
resource "aws_ssoadmin_account_assignment" "this" {
  instance_arn = aws_ssoadmin_permission_set.this.instance_arn

  permission_set_arn = aws_ssoadmin_permission_set.this.arn

  principal_id   = data.aws_identitystore_group.this.id
  principal_type = "GROUP"

  target_id   = var.target_account
  target_type = "AWS_ACCOUNT"
  provider    = aws.main
}
