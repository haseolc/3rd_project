data "aws_iam_policy_document" "cloudtrail_kms" {
  statement {
    sid    = "EnableAccountPermissions"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailEncryptLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:GenerateDataKey*",
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_source_arn]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values = [
        "arn:aws:cloudtrail:*:${data.aws_caller_identity.current.account_id}:trail/*",
      ]
    }
  }

  statement {
    sid    = "AllowCloudTrailDescribeKey"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:DescribeKey",
    ]

    resources = ["*"]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.cloudtrail_source_arn]
    }
  }
}

resource "aws_kms_key" "cloudtrail" {
  description = "KMS key for 3rd project CloudTrail audit logs"

  enable_key_rotation     = true
  deletion_window_in_days = 7
  policy                  = data.aws_iam_policy_document.cloudtrail_kms.json

  tags = {
    Name        = "3rd-project-cloudtrail-kms"
    Project     = "3rd-project"
    environment = "sandbox"
    service     = "shared-network"
    ManagedBy   = "terraform"
    Purpose     = "audit-log-encryption"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/3rd-project-cloudtrail"
  target_key_id = aws_kms_key.cloudtrail.key_id
}
