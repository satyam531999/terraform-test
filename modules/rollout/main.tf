resource "aws_appconfig_application" "this" {
  name        = "${var.name_prefix}-appconfig-app"
  description = "Feature rollout controls"

  tags = var.tags
}

data "aws_iam_policy_document" "appconfig_cloudwatch_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["appconfig.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "appconfig_cloudwatch" {
  name               = "${var.name_prefix}-appconfig-cw-role"
  assume_role_policy = data.aws_iam_policy_document.appconfig_cloudwatch_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "appconfig_cloudwatch" {
  role       = aws_iam_role.appconfig_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchReadOnlyAccess"
}

resource "aws_appconfig_environment" "this" {
  application_id = aws_appconfig_application.this.id
  name           = var.environment_name
  description    = "Environment for progressive rollout"

  dynamic "monitor" {
    for_each = var.alarm_arns
    content {
      alarm_arn      = monitor.value
      alarm_role_arn = aws_iam_role.appconfig_cloudwatch.arn
    }
  }

  tags = var.tags

  depends_on = [aws_iam_role_policy_attachment.appconfig_cloudwatch]
}

resource "aws_appconfig_configuration_profile" "flags" {
  application_id = aws_appconfig_application.this.id
  name           = "${var.name_prefix}-feature-flags"
  location_uri   = "hosted"
  type           = "AWS.Freeform"

  tags = var.tags
}

resource "aws_appconfig_hosted_configuration_version" "flags_v1" {
  application_id           = aws_appconfig_application.this.id
  configuration_profile_id = aws_appconfig_configuration_profile.flags.configuration_profile_id
  content_type             = "application/json"
  content = jsonencode({
    featureA = {
      enabled = false
    }
  })
}

resource "aws_appconfig_deployment_strategy" "gradual" {
  name                           = "${var.name_prefix}-gradual"
  description                    = "Gradual rollout with bake time"
  deployment_duration_in_minutes = var.deployment_duration_in_minutes
  final_bake_time_in_minutes     = var.final_bake_time_in_minutes
  growth_factor                  = var.growth_factor
  growth_type                    = "LINEAR"
  replicate_to                   = "NONE"

  tags = var.tags
}

resource "aws_appconfig_deployment" "initial" {
  application_id           = aws_appconfig_application.this.id
  environment_id           = aws_appconfig_environment.this.environment_id
  configuration_profile_id = aws_appconfig_configuration_profile.flags.configuration_profile_id
  configuration_version    = aws_appconfig_hosted_configuration_version.flags_v1.version_number
  deployment_strategy_id   = aws_appconfig_deployment_strategy.gradual.id
  description              = "Initial feature flag deployment"

  tags = var.tags
}
