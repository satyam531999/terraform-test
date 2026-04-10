output "integration_role_arn" {
  value = aws_iam_role.dynatrace_integration.arn
}

output "dynatrace_secret_arn" {
  value = aws_secretsmanager_secret.dynatrace_token.arn
}

output "dynatrace_api_url_parameter" {
  value = aws_ssm_parameter.dynatrace_api_url.name
}
