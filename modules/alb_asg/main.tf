data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.path_to_public_key)
}

resource "aws_lb" "app" {
  name               = "${replace(var.project_name, "_", "-")}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-alb"
  })
}

resource "aws_lb_target_group" "app" {
  name     = "${replace(var.project_name, "_", "-")}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/"
    matcher             = "200"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-tg"
  })
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.main.key_name

  iam_instance_profile {
    name = var.instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [var.web_security_group_id]
  }

  user_data = base64encode(<<-EOF
  #!/bin/bash
  set -euxo pipefail

  yum update -y
  amazon-linux-extras install php8.1 -y || true
  yum install -y httpd php php-mysqlnd mariadb aws-cli curl jq

  mkdir -p /etc/pki/rds
  curl -fsSL https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem -o /etc/pki/rds/global-bundle.pem

  systemctl enable httpd
  systemctl start httpd

  SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${var.db_secret_arn} --query SecretString --output text)

  DB_HOST=$(echo "$SECRET_JSON" | jq -r '.host')
  DB_USER=$(echo "$SECRET_JSON" | jq -r '.username')
  DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.password')

  aws s3 sync s3://${var.s3_bucket_name} /var/www/html/

  sed -i "s|##DB_HOST##|$DB_HOST|g" /var/www/html/db-config.php
  sed -i "s|##DB_USER##|$DB_USER|g" /var/www/html/db-config.php
  sed -i "s|##DB_PASSWORD##|$DB_PASSWORD|g" /var/www/html/db-config.php

  for i in {1..30}; do
    if mysql --ssl-ca=/etc/pki/rds/global-bundle.pem -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;"; then
      break
    fi
    sleep 10
  done

  mysql --ssl-ca=/etc/pki/rds/global-bundle.pem -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" < /var/www/html/articles.sql || true

  chown -R apache:apache /var/www/html
  chmod -R 755 /var/www/html
EOF
  )


  tag_specifications {
    resource_type = "instance"

    tags = merge(var.tags, {
      Name = "${var.project_name}-web"
    })
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]
  health_check_type   = "ELB"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
  }
}
