variable "aws_region" {
  type        = string
  description = "AWS region for backend resources"
  default     = "us-east-1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique S3 bucket name for Terraform state"
}

variable "lock_table_name" {
  type        = string
  description = "DynamoDB table name for Terraform state locking"
  default     = "terraform-state-locks"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to backend resources"
  default = {
    managed_by = "terraform"
    project    = "aws-prod-lab"
  }
}
