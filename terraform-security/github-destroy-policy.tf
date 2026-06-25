data "aws_iam_policy_document" "github_destroy" {
  statement {
    sid    = "TerraformStateBucket"
    effect = "Allow"

    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
    ]

    resources = [
      "arn:aws:s3:::sagal-3rd-project-tfstate-ap-northeast-2",
    ]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["3rd_project/*"]
    }
  }

  statement {
    sid    = "TerraformStateObject"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]

    resources = [
      "arn:aws:s3:::sagal-3rd-project-tfstate-ap-northeast-2/3rd_project/terraform.tfstate",
    ]
  }

  statement {
    sid    = "ReadEC2Infrastructure"
    effect = "Allow"

    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeIamInstanceProfileAssociations",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeKeyPairs",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRegions",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroupRules",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeVpcs",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-northeast-2"]
    }
  }

  statement {
    sid    = "DeleteProjectInfrastructure"
    effect = "Allow"

    actions = [
      "ec2:DeleteInternetGateway",
      "ec2:DeleteKeyPair",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateIamInstanceProfile",
      "ec2:DisassociateRouteTable",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:TerminateInstances",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-northeast-2"]
    }
  }

  statement {
    sid     = "ReadExternalSecretsInstanceProfile"
    effect  = "Allow"
    actions = ["iam:GetInstanceProfile"]

    resources = [
      aws_iam_instance_profile.external_secrets_ec2.arn,
    ]
  }
}

resource "aws_iam_policy" "github_destroy" {
  name        = "3rd-project-github-destroy"
  path        = "/3rd-project/"
  description = "Minimum permissions for the 3rd project infrastructure destroy workflow"
  policy      = data.aws_iam_policy_document.github_destroy.json

  tags = {
    Name        = "3rd-project-github-destroy"
    Project     = "3rd-project"
    Environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_destroy" {
  role       = aws_iam_role.github_destroy.name
  policy_arn = aws_iam_policy.github_destroy.arn
}
