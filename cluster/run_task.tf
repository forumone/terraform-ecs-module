resource "aws_ecr_repository" "run_task" {
  name = "${var.name}/run-task"

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "run_task" {
  repository = aws_ecr_repository.run_task.name

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
