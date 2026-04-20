terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  tags = {
    Project     = var.project_name
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

module "vpc" {
  source               = "./modules/vpc"
  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = local.tags
}

module "s3" {
  source       = "./modules/s3"
  project_name = var.project_name
  source_dir   = "${path.module}/src"
  tags         = local.tags
}

module "ec2_role_allow_s3" {
  source        = "./modules/ec2_role_allow_s3"
  count         = var.existing_instance_profile_name == null ? 1 : 0
  project_name  = var.project_name
  s3_bucket_arn = module.s3.bucket_arn
  db_secret_arn = module.secrets_manager.secret_arn
  tags          = local.tags
}


module "rds" {
  source               = "./modules/rds"
  project_name         = var.project_name
  subnet_ids           = module.vpc.private_subnet_ids
  security_group_id    = module.vpc.rds_security_group_id
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password
  db_allocated_storage = var.db_allocated_storage
  tags                 = local.tags
}

module "secrets_manager" {
  source       = "./modules/secrets_manager"
  project_name = var.project_name
  db_host      = module.rds.db_address
  db_name      = var.db_name
  db_username  = var.db_username
  db_password  = var.db_password
  tags         = local.tags
}


module "alb_asg" {
  source                = "./modules/alb_asg"
  aws_region            = var.aws_region
  project_name          = var.project_name
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  alb_security_group_id = module.vpc.alb_security_group_id
  web_security_group_id = module.vpc.web_security_group_id
  path_to_public_key    = var.path_to_public_key
  instance_type         = var.instance_type
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  asg_desired_capacity  = var.asg_desired_capacity
  s3_bucket_name        = module.s3.bucket_name
  db_secret_arn         = module.secrets_manager.secret_arn
  instance_profile_name = var.existing_instance_profile_name != null ? var.existing_instance_profile_name : module.ec2_role_allow_s3[0].instance_profile_name
  tags                  = local.tags
}


module "cloudwatch_cpu_alarms" {
  source                 = "./modules/cloudwatch_cpu_alarms"
  project_name           = var.project_name
  autoscaling_group_name = module.alb_asg.autoscaling_group_name
  sns_email              = var.sns_email
  tags                   = local.tags
}

moved {
  from = aws_vpc.main
  to   = module.vpc.aws_vpc.main
}

moved {
  from = aws_internet_gateway.main
  to   = module.vpc.aws_internet_gateway.main
}

moved {
  from = aws_subnet.public
  to   = module.vpc.aws_subnet.public
}

moved {
  from = aws_subnet.private
  to   = module.vpc.aws_subnet.private
}

moved {
  from = aws_eip.nat
  to   = module.vpc.aws_eip.nat
}

moved {
  from = aws_nat_gateway.main
  to   = module.vpc.aws_nat_gateway.main
}

moved {
  from = aws_route_table.public
  to   = module.vpc.aws_route_table.public
}

moved {
  from = aws_route_table.private
  to   = module.vpc.aws_route_table.private
}

moved {
  from = aws_route_table_association.public
  to   = module.vpc.aws_route_table_association.public
}

moved {
  from = aws_route_table_association.private
  to   = module.vpc.aws_route_table_association.private
}

moved {
  from = aws_security_group.alb
  to   = module.vpc.aws_security_group.alb
}

moved {
  from = aws_security_group.web
  to   = module.vpc.aws_security_group.web
}

moved {
  from = aws_security_group.rds
  to   = module.vpc.aws_security_group.rds
}

moved {
  from = random_id.suffix
  to   = module.s3.random_id.suffix
}

moved {
  from = aws_s3_bucket.app
  to   = module.s3.aws_s3_bucket.app
}

moved {
  from = aws_s3_bucket_ownership_controls.app
  to   = module.s3.aws_s3_bucket_ownership_controls.app
}

moved {
  from = aws_s3_bucket_public_access_block.app
  to   = module.s3.aws_s3_bucket_public_access_block.app
}

moved {
  from = aws_s3_object.app_src
  to   = module.s3.aws_s3_object.app_src
}

moved {
  from = aws_iam_role.ec2
  to   = module.ec2_role_allow_s3[0].aws_iam_role.ec2
}

moved {
  from = aws_iam_role_policy.ec2_s3_access
  to   = module.ec2_role_allow_s3[0].aws_iam_role_policy.ec2_s3_access
}

moved {
  from = aws_iam_instance_profile.ec2
  to   = module.ec2_role_allow_s3[0].aws_iam_instance_profile.ec2
}

moved {
  from = aws_db_subnet_group.main
  to   = module.rds.aws_db_subnet_group.main
}

moved {
  from = aws_db_instance.main
  to   = module.rds.aws_db_instance.main
}

moved {
  from = aws_key_pair.main
  to   = module.alb_asg.aws_key_pair.main
}

moved {
  from = aws_lb.app
  to   = module.alb_asg.aws_lb.app
}

moved {
  from = aws_lb_target_group.app
  to   = module.alb_asg.aws_lb_target_group.app
}

moved {
  from = aws_lb_listener.http
  to   = module.alb_asg.aws_lb_listener.http
}

moved {
  from = aws_launch_template.web
  to   = module.alb_asg.aws_launch_template.web
}

moved {
  from = aws_autoscaling_group.web
  to   = module.alb_asg.aws_autoscaling_group.web
}

moved {
  from = aws_autoscaling_policy.scale_up
  to   = module.cloudwatch_cpu_alarms.aws_autoscaling_policy.scale_up
}

moved {
  from = aws_autoscaling_policy.scale_down
  to   = module.cloudwatch_cpu_alarms.aws_autoscaling_policy.scale_down
}

moved {
  from = aws_cloudwatch_metric_alarm.cpu_high
  to   = module.cloudwatch_cpu_alarms.aws_cloudwatch_metric_alarm.cpu_high
}

moved {
  from = aws_cloudwatch_metric_alarm.cpu_low
  to   = module.cloudwatch_cpu_alarms.aws_cloudwatch_metric_alarm.cpu_low
}
