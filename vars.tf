variable "aws_region" {
  description = "AWS region where resources are deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix for resources."
  type        = string
  default     = "terraform-aws"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs used by the ALB and NAT Gateway."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Two private subnet CIDRs used by EC2 and RDS."
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "instance_type" {
  description = "Instance type for web servers."
  type        = string
  default     = "t2.micro"
}

variable "asg_min_size" {
  description = "ASG minimum number of instances."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "ASG maximum number of instances."
  type        = number
  default     = 4
}

variable "asg_desired_capacity" {
  description = "ASG desired number of instances."
  type        = number
  default     = 2
}

variable "db_name" {
  description = "Application database name."
  type        = string
  default     = "blog"
}

variable "db_username" {
  description = "Master username for MariaDB."
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "Master password for MariaDB."
  type        = string
  sensitive   = true
}

variable "db_allocated_storage" {
  description = "Allocated storage (GiB) for RDS."
  type        = number
  default     = 20
}

variable "path_to_public_key" {
  description = "Path to the SSH public key used to create EC2 key pair."
  type        = string
  default     = "keys/terraform.pub"
}

variable "existing_instance_profile_name" {
  description = "Existing IAM instance profile to attach to EC2 instances. Set to null to create one in Terraform. In AWS Academy labs, override this with LabInstanceProfile only if it already has S3 and Secrets Manager access."
  type        = string
  default     = null
  nullable    = true
}