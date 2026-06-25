data "aws_iam_policy_document" "github_destroy_assume_role" {
  statement {
    sid     = "GitHubActionsMainBranch"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github_actions.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:haseolc/3rd_project:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_destroy" {
  name                 = "3rd-project-github-destroy"
  path                 = "/3rd-project/"
  assume_role_policy   = data.aws_iam_policy_document.github_destroy_assume_role.json
  max_session_duration = 3600

  tags = {
    Name        = "3rd-project-github-destroy"
    Project     = "3rd-project"
    Environment = "sandbox"
    ManagedBy   = "terraform"
    Purpose     = "github-actions-infra-destroy"
  }
}
