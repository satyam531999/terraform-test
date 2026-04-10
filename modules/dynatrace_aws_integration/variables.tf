variable "name_prefix" {
  type = string
}

variable "dynatrace_aws_account_arn" {
  type        = string
  description = "Dynatrace AWS account ARN used to assume integration role"
}

variable "dynatrace_external_id" {
  type        = string
  description = "External ID configured in Dynatrace for secure role assumption"
}

variable "dynatrace_api_url" {
  type        = string
  description = "Dynatrace environment API URL"
}

variable "dynatrace_api_token" {
  type        = string
  description = "Dynatrace API token"
  default     = ""
  sensitive   = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
