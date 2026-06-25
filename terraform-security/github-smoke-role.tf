data "aws_iam_policy_document" "github_smoke_assume_role" {
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

resource "aws_iam_role" "github_smoke" {
  name                 = "3rd-project-github-smoke"
  path                 = "/3rd-project/"
  assume_role_policy   = data.aws_iam_policy_document.github_smoke_assume_role.json
  max_session_duration = 3600

  tags = {
    Name        = "3rd-project-github-smoke"
    Project     = "3rd-project"
    Environment = "sandbox"
    ManagedBy   = "terraform"
    Purpose     = "github-actions-smoke-cd"
  }
}

data "aws_iam_policy_document" "github_smoke" {
  statement {
    sid       = "DescribeKubernetesMaster"
    effect    = "Allow"
    actions   = ["ec2:DescribeInstances"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "github_smoke" {
  name        = "3rd-project-github-smoke-read"
  path        = "/3rd-project/"
  description = "Minimum EC2 read permission for the 3rd project smoke CD workflow"
  policy      = data.aws_iam_policy_document.github_smoke.json

  tags = {
    Name        = "3rd-project-github-smoke-read"
    Project     = "3rd-project"
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_smoke" {
  role       = aws_iam_role.github_smoke.name
  policy_arn = aws_iam_policy.github_smoke.arn
}
