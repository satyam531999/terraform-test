variable "name_prefix" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "target_group_arn_suffix" {
  type = string
}

variable "alb_5xx_threshold" {
  type    = number
  default = 5
}

variable "alb_latency_threshold_seconds" {
  type    = number
  default = 1.0
}

variable "notification_topic_arn" {
  type    = string
  default = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
