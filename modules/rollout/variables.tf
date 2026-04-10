variable "name_prefix" {
  type = string
}

variable "environment_name" {
  type    = string
  default = "default"
}

variable "alarm_arns" {
  type    = list(string)
  default = []
}

variable "deployment_duration_in_minutes" {
  type    = number
  default = 20
}

variable "final_bake_time_in_minutes" {
  type    = number
  default = 5
}

variable "growth_factor" {
  type    = number
  default = 20
}

variable "tags" {
  type    = map(string)
  default = {}
}
