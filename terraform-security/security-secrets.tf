############################################################
# KMS Key for Secrets Manager
############################################################

resource "aws_kms_key" "secrets_manager" {
  description = "KMS key for 3rd project Secrets Manager"

  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Name         = "3rd-project-secrets-kms"
    Project      = "3rd-project"
    owner        = "team-leader"
    environment  = "sandbox"
    "auto-stop"  = "false"
    service      = "shared-network"
    team         = "infra"
    "created-by" = "terraform"
    ManagedBy    = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "secrets_manager" {
  name          = "alias/3rd-project-secrets"
  target_key_id = aws_kms_key.secrets_manager.key_id
}

############################################################
# Secrets Manager - PostgreSQL
############################################################

resource "aws_secretsmanager_secret" "postgresql" {
  name        = "3rd-project/sandbox/postgresql"
  description = "PostgreSQL credentials for the 3rd project"

  kms_key_id = aws_kms_key.secrets_manager.arn

  recovery_window_in_days = 7

  tags = {
    Name        = "3rd-project-postgresql-secret"
    Project     = "3rd-project"
    environment = "sandbox"
    service     = "shared-network"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}
