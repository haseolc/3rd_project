data "aws_iam_policy_document" "github_provision" {
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
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstanceTypes",
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
      "ec2:DescribeVolumeStatus",
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
    sid    = "ManageProjectInfrastructure"
    effect = "Allow"

    actions = [
      "ec2:AssociateIamInstanceProfile",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateFlowLogs",
      "ec2:CreateInternetGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
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
      "ec2:ImportKeyPair",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyInstanceMetadataOptions",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:MonitorInstances",
      "ec2:ReplaceIamInstanceProfileAssociation",
      "ec2:ReplaceRoute",
      "ec2:ReplaceRouteTableAssociation",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:UnmonitorInstances",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-northeast-2"]
    }
  }

  statement {
    sid    = "ManageProjectLoadBalancerAndWAF"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:CreateWebACLAssociation",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeleteWebACLAssociation",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeAccountLimits",
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
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyListenerAttributes",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebAcl",
      "wafv2:AssociateWebACL",
      "wafv2:CreateWebACL",
      "wafv2:DeleteLoggingConfiguration",
      "wafv2:DeleteWebACL",
      "wafv2:DescribeManagedRuleGroup",
      "wafv2:DisassociateWebACL",
      "wafv2:GetLoggingConfiguration",
      "wafv2:GetWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:ListAvailableManagedRuleGroups",
      "wafv2:ListResourcesForWebACL",
      "wafv2:ListTagsForResource",
      "wafv2:ListWebACLs",
      "wafv2:PutLoggingConfiguration",
      "wafv2:TagResource",
      "wafv2:UntagResource",
      "wafv2:UpdateWebACL",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-northeast-2"]
    }
  }

  statement {
    sid    = "ManageWAFCloudWatchLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogDelivery",
      "logs:CreateLogGroup",
      "logs:DeleteLogDelivery",
      "logs:DeleteLogGroup",
      "logs:DescribeLogGroups",
      "logs:DescribeResourcePolicies",
      "logs:ListTagsForResource",
      "logs:PutResourcePolicy",
      "logs:PutRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = ["ap-northeast-2"]
    }
  }

  statement {
    sid       = "CreateELBServiceLinkedRole"
    effect    = "Allow"
    actions   = ["iam:CreateServiceLinkedRole"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values   = ["elasticloadbalancing.amazonaws.com"]
    }
  }

  statement {
    sid    = "ReadExternalSecretsInstanceProfile"
    effect = "Allow"

    actions = [
      "iam:GetInstanceProfile",
    ]

    resources = [
      aws_iam_instance_profile.external_secrets_ec2.arn,
    ]
  }

  statement {
    sid    = "PassExternalSecretsRoleToEC2"
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      aws_iam_role.external_secrets_ec2.arn,
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "github_provision" {
  name        = "3rd-project-github-provision"
  path        = "/3rd-project/"
  description = "Minimum permissions for the 3rd project infrastructure provision workflow"
  policy      = data.aws_iam_policy_document.github_provision.json

  tags = {
    Name        = "3rd-project-github-provision"
    Project     = "3rd-project"
    environment = "sandbox"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_provision" {
  role       = aws_iam_role.github_provision.name
  policy_arn = aws_iam_policy.github_provision.arn
}
