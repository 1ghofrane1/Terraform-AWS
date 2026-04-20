output "alb_dns_name" {
  value = aws_lb.app.dns_name
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.web.name
}
