resource "aws_ecr_repository" "watchtower_repository" {
  name = "watchtower-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}