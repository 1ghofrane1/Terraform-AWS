variable "project_name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_security_group_id" {
  type = string
}

variable "web_security_group_id" {
  type = string
}

variable "path_to_public_key" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "asg_min_size" {
  type = number
}

variable "asg_max_size" {
  type = number
}

variable "asg_desired_capacity" {
  type = number
}

variable "s3_bucket_name" {
  type = string
}

variable "instance_profile_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "db_secret_arn" {
  type = string
}
