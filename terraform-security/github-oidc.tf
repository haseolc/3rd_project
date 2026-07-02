resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  tags = {
    Name        = "3rd-project-github-actions-oidc"
    Project     = "3rd-project"
    environment = "sandbox"
    ManagedBy   = "terraform"
  }
}
