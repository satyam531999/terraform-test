output "state_bucket_name" {
  value       = aws_s3_bucket.tf_state.id
  description = "S3 bucket used for Terraform state"
}

output "lock_table_name" {
  value       = aws_dynamodb_table.tf_lock.name
  description = "DynamoDB table used for Terraform state lock"
}
