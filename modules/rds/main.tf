resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-db-subnet-group"
  })
}

resource "aws_db_instance" "main" {
  identifier              = "${var.project_name}-db"
  engine                  = "mariadb"
  instance_class          = "db.t3.micro"
  allocated_storage       = var.db_allocated_storage
  max_allocated_storage   = var.db_allocated_storage
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  backup_retention_period = 1
  multi_az                = true
  publicly_accessible     = false
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [var.security_group_id]

  tags = merge(var.tags, {
    Name = "${var.project_name}-db"
  })
}
