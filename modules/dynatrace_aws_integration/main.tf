data "aws_iam_policy_document" "assume_dynatrace" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [var.dynatrace_aws_account_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.dynatrace_external_id]
    }
  }
}

resource "aws_iam_role" "dynatrace_integration" {
  name               = "${var.name_prefix}-dynatrace-integration-role"
  assume_role_policy = data.aws_iam_policy_document.assume_dynatrace.json

  tags = var.tags
}

data "aws_iam_policy_document" "dynatrace_read" {
  statement {
    sid    = "DynatraceReadOnlyCore"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:FilterLogEvents",
      "ec2:Describe*",
      "ecs:Describe*",
      "ecs:List*",
      "elasticloadbalancing:Describe*",
      "rds:Describe*",
      "lambda:List*",
      "lambda:Get*",
      "tag:GetResources",
      "autoscaling:Describe*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "dynatrace_read" {
  name   = "${var.name_prefix}-dynatrace-read-policy"
  policy = data.aws_iam_policy_document.dynatrace_read.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "dynatrace_read" {
  role       = aws_iam_role.dynatrace_integration.name
  policy_arn = aws_iam_policy.dynatrace_read.arn
}

resource "aws_secretsmanager_secret" "dynatrace_token" {
  name        = "${var.name_prefix}/dynatrace/api-token"
  description = "Dynatrace API token"

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "dynatrace_token" {
  count         = var.dynatrace_api_token == "" ? 0 : 1
  secret_id     = aws_secretsmanager_secret.dynatrace_token.id
  secret_string = var.dynatrace_api_token
}

resource "aws_ssm_parameter" "dynatrace_api_url" {
  name  = "/${var.name_prefix}/dynatrace/api-url"
  type  = "String"
  value = var.dynatrace_api_url

  tags = var.tags
}
