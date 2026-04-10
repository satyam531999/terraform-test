output "appconfig_application_id" {
  value = aws_appconfig_application.this.id
}

output "appconfig_environment_id" {
  value = aws_appconfig_environment.this.environment_id
}

output "appconfig_configuration_profile_id" {
  value = aws_appconfig_configuration_profile.flags.configuration_profile_id
}
