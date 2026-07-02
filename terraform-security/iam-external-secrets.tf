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
    environment = "sandbox"
    service     = "shared-network"
    ManagedBy   = "terraform"
  }
}

############################################################
# EC2 Assume Role Policy for External Secrets Operator
############################################################

data "aws_iam_policy_document" "external_secrets_ec2_assume_role" {
  statement {
    sid     = "AllowEC2AssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

############################################################
# IAM Role for External Secrets Operator EC2 Node
############################################################

resource "aws_iam_role" "external_secrets_ec2" {
  name        = "3rd-project-external-secrets-ec2"
  description = "EC2 role used by External Secrets Operator"
  path        = "/3rd-project/"

  assume_role_policy = data.aws_iam_policy_document.external_secrets_ec2_assume_role.json

  tags = {
    Name        = "3rd-project-external-secrets-ec2"
    Project     = "3rd-project"
    environment = "sandbox"
    service     = "shared-network"
    ManagedBy   = "terraform"
  }
}


############################################################
# Attach Least-Privilege Policy to EC2 Role
############################################################

resource "aws_iam_role_policy_attachment" "external_secrets_read" {
  role       = aws_iam_role.external_secrets_ec2.name
  policy_arn = aws_iam_policy.external_secrets_read.arn
}


############################################################
# EC2 Instance Profile
############################################################

resource "aws_iam_instance_profile" "external_secrets_ec2" {
  name = "3rd-project-external-secrets-ec2"
  path = "/3rd-project/"
  role = aws_iam_role.external_secrets_ec2.name

  tags = {
    Name        = "3rd-project-external-secrets-ec2"
    Project     = "3rd-project"
    environment = "sandbox"
    service     = "shared-network"
    ManagedBy   = "terraform"
  }
}
