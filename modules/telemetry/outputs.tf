output "alarm_arns" {
  value = [
    aws_cloudwatch_metric_alarm.alb_5xx.arn,
    aws_cloudwatch_metric_alarm.alb_latency.arn
  ]
}

output "dashboard_name" {
  value = aws_cloudwatch_dashboard.ops.dashboard_name
}
