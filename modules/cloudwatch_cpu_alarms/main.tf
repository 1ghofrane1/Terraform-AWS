locals {
  notification_action_arns = var.sns_email == null ? [] : [aws_sns_topic.asg_notifications[0].arn]
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-scale-up"
  autoscaling_group_name = var.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 300
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-scale-down"
  autoscaling_group_name = var.autoscaling_group_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 300
}

resource "aws_sns_topic" "asg_notifications" {
  count = var.sns_email == null ? 0 : 1

  name = "${var.project_name}-asg-notifications"

  tags = merge(var.tags, {
    Name = "${var.project_name}-asg-notifications"
  })
}

resource "aws_sns_topic_subscription" "email" {
  count = var.sns_email == null ? 0 : 1

  topic_arn = aws_sns_topic.asg_notifications[0].arn
  protocol  = "email"
  endpoint  = var.sns_email
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project_name}-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Scale up when average CPU >= 80%"
  alarm_actions       = concat([aws_autoscaling_policy.scale_up.arn], local.notification_action_arns)

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "${var.project_name}-cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "Scale down when average CPU < 5%"
  alarm_actions       = concat([aws_autoscaling_policy.scale_down.arn], local.notification_action_arns)

  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
}
