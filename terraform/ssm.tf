resource "aws_secretsmanager_secret" "watchTower_db_uri" {
  name = "watchTower_database_uri_secret"
  description = "MongoDB connection URI for WatchTower"
  tags = {
    Name = "watchTower DB URI Secret"
    Environment = "Dev"
  }

}

resource "aws_secretsmanager_secret_version" "watchTower_db_uri_version" {
  secret_id = aws_secretsmanager_secret.watchTower_db_uri.id
  secret_string = var.mongoDB_uri
}

resource "aws_secretsmanager_secret" "payload_secret" {
  name = "watchTower_payload_secret"
  description = "Secret for WatchTower payload"
  tags = {
    Name = "watchTower Payload Secret"
    Environment = "Dev"
  }
}

resource "aws_secretsmanager_secret_version" "payload_secret_version" {
  secret_id = aws_secretsmanager_secret.payload_secret.id
  secret_string = var.payload_secret
}

resource "aws_iam_role_policy" "ssm_role_policy" {
  name = "ecs_ssm_access_policy"
  role = aws_iam_role.ecs_execution_role.name
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Effect = "Allow"
            Action = [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
            ]
            Resource = [
                aws_secretsmanager_secret.watchTower_db_uri.arn,
                aws_secretsmanager_secret.payload_secret.arn
            ]
        }
    ]
  })
}