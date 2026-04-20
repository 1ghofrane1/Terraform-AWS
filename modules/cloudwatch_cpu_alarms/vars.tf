variable "project_name" {
  type = string
}

variable "autoscaling_group_name" {
  type = string
}

variable "sns_email" {
  type     = string
  default  = null
  nullable = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
