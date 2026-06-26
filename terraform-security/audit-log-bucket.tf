data "aws_caller_identity" "current" {}

locals {
  audit_log_bucket_name = "sagal-3rd-project-audit-logs-${data.aws_caller_identity.current.account_id}-ap-northeast-2"
  cloudtrail_name       = "3rd-project-security-audit"
  cloudtrail_s3_prefix  = "cloudtrail"
  alb_access_log_prefix = "alb"
  cloudtrail_source_arn = "arn:aws:cloudtrail:ap-northeast-2:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
}

resource "aws_s3_bucket" "audit_logs" {
  bucket        = local.audit_log_bucket_name
  force_destroy = false

  tags = {
    Name        = "3rd-project-audit-logs"
    Project     = "3rd-project"
    environment = "sandbox"
    ManagedBy   = "terraform"
    Purpose     = "security-audit-logs"
  }
}

resource "aws_s3_bucket_ownership_controls" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    id     = "audit-log-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

data "aws_iam_policy_document" "audit_logs" {
  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = [
      aws_s3_bucket.audit_logs.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:*",
      ]
    }
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.audit_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:logs:ap-northeast-2:${data.aws_caller_identity.current.account_id}:*",
      ]
    }
  }

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:GetBucketAcl"]

    resources = [
      aws_s3_bucket.audit_logs.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_source_arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.audit_logs.arn}/${local.cloudtrail_s3_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_source_arn]
    }
  }

  statement {
    sid    = "AWSLoadBalancerLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logdelivery.elasticloadbalancing.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.audit_logs.arn}/${local.alb_access_log_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
    ]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:elasticloadbalancing:ap-northeast-2:${data.aws_caller_identity.current.account_id}:loadbalancer/*",
      ]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.audit_logs.arn,
      "${aws_s3_bucket.audit_logs.arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  policy = data.aws_iam_policy_document.audit_logs.json

  depends_on = [
    aws_s3_bucket_ownership_controls.audit_logs,
    aws_s3_bucket_public_access_block.audit_logs,
  ]
}
