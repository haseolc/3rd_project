resource "aws_cloudtrail" "security_audit" {
  name           = local.cloudtrail_name
  s3_bucket_name = aws_s3_bucket.audit_logs.id
  s3_key_prefix  = local.cloudtrail_s3_prefix
  kms_key_id     = aws_kms_key.cloudtrail.arn

  enable_logging                = true
  enable_log_file_validation    = true
  include_global_service_events = true
  is_multi_region_trail         = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = {
    Name        = "3rd-project-security-audit"
    Project     = "3rd-project"
    environment = "sandbox"
    ManagedBy   = "terraform"
    Purpose     = "account-api-audit"
  }

  depends_on = [
    aws_s3_bucket_policy.audit_logs,
  ]
}
