data "aws_caller_identity" "current" {}

locals {
  audit_log_bucket_arn = "arn:aws:s3:::sagal-3rd-project-audit-logs-${data.aws_caller_identity.current.account_id}-ap-northeast-2"
}

resource "aws_flow_log" "main_vpc" {
  vpc_id               = aws_vpc.main_vpc.id
  traffic_type         = "ALL"
  log_destination_type = "s3"
  log_destination      = local.audit_log_bucket_arn

  max_aggregation_interval = 60

  tags = {
    Name       = "main-vpc-flow-logs"
    purpose    = "network-audit"
    created-by = "terraform"
  }
}
