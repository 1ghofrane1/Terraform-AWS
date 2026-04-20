output "sns_topic_arn" {
  description = "SNS topic ARN used for Auto Scaling alarm notifications."
  value       = var.sns_email == null ? null : aws_sns_topic.asg_notifications[0].arn
}
