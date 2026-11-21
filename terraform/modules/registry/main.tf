# -----------------------------------------------------------------------------
# Registry module: private container registry (Amazon ECR).
#
#   * Images are pushed by the deployment pipeline and pulled by the server.
#   * Tags are immutable: a tag such as a commit hash can never be overwritten,
#     so what was tested is exactly what runs, and a rollback is a known image.
#   * Every pushed image is scanned for vulnerabilities by ECR.
#   * Encrypted at rest. Old images are expired automatically.
# -----------------------------------------------------------------------------

resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = "IMMUTABLE"
  force_delete         = var.force_delete

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Remove untagged images after 7 days"

        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }

        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep the ${var.keep_last_images} most recent images"

        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.keep_last_images
        }

        action = {
          type = "expire"
        }
      },
    ]
  })
}
