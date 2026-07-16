data "aws_vpc" "shared" {
  id = var.shared_vpc_id
}

data "aws_subnet" "public_a" {
  id = var.public_subnet_id
}

data "aws_security_group" "k8s" {
  id = var.k8s_security_group_id
}

data "aws_iam_instance_profile" "external_secrets" {
  name = "3rd-project-external-secrets-ec2"
}

data "aws_lb" "k8s" {
  name = "k8s-alb-v2"
}

data "aws_lb_target_group" "k8s_ingress" {
  name = "k8s-ingress-tg-v2"
}
