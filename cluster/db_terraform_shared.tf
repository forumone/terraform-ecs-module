# Create ECR Repo
resource "aws_ecr_repository" "terraform_database" {
  name = "${var.name}/terraform"
}

resource "aws_ecr_lifecycle_policy" "terraform_database" {
  repository = aws_ecr_repository.terraform_database.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 24 hours"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }

        action = {
          type = "expire"
        }
      }
    ]
  })
}

# CloudWatch log group
resource "aws_cloudwatch_log_group" "terraform" {
  name              = "/${var.name}/services/terraform"
  retention_in_days = var.logs.retention
}
