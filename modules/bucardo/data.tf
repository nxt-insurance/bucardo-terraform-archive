data "aws_secretsmanager_secret_version" "rds_admin_credentials" {
  secret_id = var.rds_instance.admin_credentials_arn
}

data "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = "arn:aws:secretsmanager:[redacted]"
}

data "aws_secretsmanager_secret_version" "heroku_database_urls" {
  secret_id = "arn:aws:secretsmanager:[redacted]"
}
