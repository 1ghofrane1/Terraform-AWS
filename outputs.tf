output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer."
  value       = module.alb_asg.alb_dns_name
}

output "db_endpoint" {
  description = "RDS endpoint (hostname:port)."
  value       = module.rds.db_endpoint
}

output "db_address" {
  description = "RDS hostname address."
  value       = module.rds.db_address
}

output "db_port" {
  description = "RDS port."
  value       = module.rds.db_port
}

output "db_name" {
  description = "Application database name."
  value       = module.rds.db_name
}

output "db_username" {
  description = "RDS master username."
  value       = module.rds.db_username
}

output "s3_bucket_name" {
  description = "S3 bucket used to store app source files."
  value       = module.s3.bucket_name
}

output "autoscaling_group_name" {
  description = "Auto Scaling Group name for web instances."
  value       = module.alb_asg.autoscaling_group_name
}
