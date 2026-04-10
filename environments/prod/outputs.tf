output "alb_dns_name" {
  value = module.compute.alb_dns_name
}

output "ecs_cluster_name" {
  value = module.compute.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.compute.ecs_service_name
}

output "ops_dashboard_name" {
  value = module.telemetry.dashboard_name
}

output "dynatrace_integration_role_arn" {
  value = length(module.dynatrace) > 0 ? module.dynatrace[0].integration_role_arn : "dynatrace-not-enabled"
}
