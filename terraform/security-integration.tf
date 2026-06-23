############################################################
# Security Resources Integration
############################################################

data "aws_iam_instance_profile" "external_secrets" {
  name = "3rd-project-external-secrets-ec2"
}
