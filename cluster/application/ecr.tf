# Create a repository for each of this application's containers
resource "aws_ecr_repository" "repository" {
  for_each = toset(var.application.containers)

  name = "${var.cluster_name}/${var.application.name}/${each.value}"

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "repository" {
  for_each = toset(var.application.containers)

  repository = aws_ecr_repository.repository[each.key].name

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
