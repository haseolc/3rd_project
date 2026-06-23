############################################################
# IAM Policy Document for External Secrets Operator
############################################################

data "aws_iam_policy_document" "external_secrets_read" {
  statement {
    sid    = "ReadPostgreSQLSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:GetResourcePolicy"
    ]

    resources = [
      aws_secretsmanager_secret.postgresql.arn
    ]
  }

  statement {
    sid    = "DecryptPostgreSQLSecret"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey"
    ]

    resources = [
      aws_kms_key.secrets_manager.arn
    ]
  }
}

############################################################
# IAM Managed Policy for External Secrets Operator
############################################################

resource "aws_iam_policy" "external_secrets_read" {
  name        = "3rd-project-external-secrets-read"
  description = "Allows External Secrets Operator to read the PostgreSQL secret"
  path        = "/3rd-project/"

  policy = data.aws_iam_policy_document.external_secrets_read.json

  tags = {
    Name        = "3rd-project-external-secrets-read"
    Project     = "3rd-project"
    Environment = "sandbox"
    Service     = "external-secrets"
    ManagedBy   = "terraform"
  }
}
