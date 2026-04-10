module "network" {
  source = "../../modules/network"

  name_prefix          = var.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  tags                 = var.tags
}

module "compute" {
  source = "../../modules/compute_ecs"

  name_prefix        = var.name_prefix
  aws_region         = var.aws_region
  vpc_id             = module.network.vpc_id
  public_subnet_ids  = module.network.public_subnet_ids
  private_subnet_ids = module.network.private_subnet_ids
  container_image    = var.container_image
  container_port     = var.container_port
  desired_count      = var.desired_count
  cpu                = var.cpu
  memory             = var.memory
  tags               = var.tags
}

module "telemetry" {
  source = "../../modules/telemetry"

  name_prefix              = var.name_prefix
  aws_region               = var.aws_region
  alb_arn_suffix           = module.compute.alb_arn_suffix
  target_group_arn_suffix  = module.compute.target_group_arn_suffix
  alb_5xx_threshold        = var.alb_5xx_threshold
  alb_latency_threshold_seconds = var.alb_latency_threshold_seconds
  notification_topic_arn   = var.notification_topic_arn
  tags                     = var.tags
}

module "rollout" {
  source = "../../modules/rollout"

  name_prefix                    = var.name_prefix
  environment_name               = "dev"
  alarm_arns                     = module.telemetry.alarm_arns
  deployment_duration_in_minutes = var.deployment_duration_in_minutes
  final_bake_time_in_minutes     = var.final_bake_time_in_minutes
  growth_factor                  = var.growth_factor
  tags                           = var.tags
}

module "dynatrace" {
  count  = var.enable_dynatrace ? 1 : 0
  source = "../../modules/dynatrace_aws_integration"

  name_prefix               = var.name_prefix
  dynatrace_aws_account_arn = var.dynatrace_aws_account_arn
  dynatrace_external_id     = var.dynatrace_external_id
  dynatrace_api_url         = var.dynatrace_api_url
  dynatrace_api_token       = var.dynatrace_api_token
  tags                      = var.tags
}
