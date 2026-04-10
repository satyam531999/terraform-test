variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "name_prefix" {
  type    = string
  default = "prodlab-prod"
}

variable "vpc_cidr" {
  type    = string
  default = "10.20.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.1.0/24", "10.20.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.20.101.0/24", "10.20.102.0/24"]
}

variable "container_image" {
  type    = string
  default = "public.ecr.aws/nginx/nginx:latest"
}

variable "container_port" {
  type    = number
  default = 80
}

variable "desired_count" {
  type    = number
  default = 2
}

variable "cpu" {
  type    = number
  default = 512
}

variable "memory" {
  type    = number
  default = 1024
}

variable "alb_5xx_threshold" {
  type    = number
  default = 10
}

variable "alb_latency_threshold_seconds" {
  type    = number
  default = 0.75
}

variable "notification_topic_arn" {
  type    = string
  default = ""
}

variable "deployment_duration_in_minutes" {
  type    = number
  default = 30
}

variable "final_bake_time_in_minutes" {
  type    = number
  default = 10
}

variable "growth_factor" {
  type    = number
  default = 10
}

variable "dynatrace_aws_account_arn" {
  type    = string
  default = "arn:aws:iam::123456789012:root"
}

variable "dynatrace_external_id" {
  type    = string
  default = "replace-me-external-id"
}

variable "dynatrace_api_url" {
  type    = string
  default = "https://your-env.live.dynatrace.com/api"
}

variable "dynatrace_api_token" {
  type      = string
  default   = ""
  sensitive = true
}

variable "enable_dynatrace" {
  type        = bool
  description = "Set to true when real Dynatrace credentials are available"
  default     = false
}

variable "tags" {
  type = map(string)
  default = {
    managed_by  = "terraform"
    project     = "aws-prod-lab"
    env         = "prod"
    criticality = "high"
  }
}
