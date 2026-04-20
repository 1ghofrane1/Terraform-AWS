resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.project_name}/db"
  description             = "Database credentials for ${var.project_name}"
  recovery_window_in_days = 0

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-secret"
  })
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    host     = var.db_host
    dbname   = var.db_name
    username = var.db_username
    password = var.db_password
  })
}
