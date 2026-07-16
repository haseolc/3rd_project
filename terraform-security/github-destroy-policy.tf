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
      "ec2:DescribeFlowLogs",
      "ec2:DescribeIamInstanceProfileAssociations",
      "ec2:DescribeImages",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceCreditSpecifications",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
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
      "ec2:DeleteFlowLogs",
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
    sid    = "DeleteProjectLoadBalancerAndWAF"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeleteWebACLAssociation",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerAttributes",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:DescribeWebACLAssociation",
      "elasticloadbalancing:GetLoadBalancerWebACL",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetWebAcl",
      "wafv2:DeleteLoggingConfiguration",
      "wafv2:DeleteWebACL",
      "wafv2:DisassociateWebACL",
      "wafv2:GetLoggingConfiguration",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:ListResourcesForWebACL",
      "wafv2:ListTagsForResource",
      "wafv2:ListWebACLs",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-northeast-2"]
    }
  }

  statement {
    sid    = "DeleteProjectRDS"
    effect = "Allow"

    actions = [
      "rds:DeleteDBInstance",
      "rds:DeleteDBSubnetGroup",
      "rds:Describe*",
      "rds:ListTagsForResource",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-northeast-2"]
    }
  }

  statement {
    sid    = "DeleteWAFCloudWatchLogging"
    effect = "Allow"

    actions = [
      "logs:DeleteLogDelivery",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:DescribeResourcePolicies",
      "logs:ListTagsForResource",
      "logs:PutResourcePolicy",
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
    environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_destroy" {
  role       = aws_iam_role.github_destroy.name
  policy_arn = aws_iam_policy.github_destroy.arn
}
