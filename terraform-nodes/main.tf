resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzF9Hnf895nUIr/B3pM5qmpuItc24KXQSh/2m9/imLv/fh+9xDO8FqGWs7bLJCi2IkXbJSnIi8nWnZx/FUyL5+YTb75eQPFVF5x5QfPOIky7Y7zZwjElDqqiq+djU5jbYaULlY8uGsaez56tZn5uoP6ses3KpuKuCRs7pTJf46DFwM2KNcWKuub4P0nVFQGeNjWpY9+DNDg/Hnxlo1SM0H/B6bXXyuSHjOtIxBOWr4MIJZ9yR1dduH8GVab8PVU8CaR1F+PlZt9jseDNS4V6Bt7R4ME76qVdM22o6+hnUfTZ8Z3uq7pAoZe3WI9SUPV0+Z7PJsbg4R+LF/Ly2OJjlHqZddInKHX4ENnHDFxwZR5BX1/Gk6QzYyR5Ges4Eqv8CvsP1LSjHHRmVLNL244/EOCuuZeUVp4J5+EwhEHTdKgiygcXsteJB84zwBYNj/o3+3KXib2GAUdZ3u60xKfIkz+9C7tOQbcz1nSWqOKV+Qb05hAxr5PtDHM1hzpZQc5tgkBlLJIPpyID8Pn+YOWdu3eDzDcCLitQA7l507rCub1k2sJb0EiqxpCfSskekk6LSq3ez9ClXYbk4F57fN7lc/ibDWPCnMMXmSbQLaZ10PSX7/tFwabmVegxcKdH6hYnkwKfaxmX7XsU97qbD5d3O+DkgDHPD+JlRkl/qq5rHKmw== ubuntu@ubuntu-2204"

  tags = {
    Name       = "k8s-key"
    service    = "user-service"
    team       = "infra"
    owner      = "team-leader"
    auto-stop  = "true"
    created-by = "terraform"
  }
}

resource "aws_instance" "k8s_master" {
  #checkov:skip=CKV_AWS_88:Public IP is temporarily required for GitHub-hosted runner SSH; port 22 is limited to the runner IP /32 and revoked after the workflow.
  ami                         = "ami-0c9c942bd7bf113a2"
  instance_type               = "t3.medium"
  ebs_optimized               = true
  monitoring                  = true
  subnet_id                   = data.aws_subnet.public_a.id
  vpc_security_group_ids      = [data.aws_security_group.k8s.id]
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  tags = {
    Name       = "k8s-master"
    service    = "user-service"
    team       = "infra"
    owner      = "team-leader"
    auto-stop  = "true"
    created-by = "terraform"
  }
}

resource "aws_instance" "k8s_worker_1" {
  #checkov:skip=CKV_AWS_88:Public IP is temporarily required for GitHub-hosted runner SSH; port 22 is limited to the runner IP /32 and revoked after the workflow.
  ami                         = "ami-0c9c942bd7bf113a2"
  instance_type               = "t3.medium"
  ebs_optimized               = true
  monitoring                  = true
  subnet_id                   = data.aws_subnet.public_a.id
  vpc_security_group_ids      = [data.aws_security_group.k8s.id]
  iam_instance_profile        = data.aws_iam_instance_profile.external_secrets.name
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  tags = {
    Name       = "k8s-worker-1"
    service    = "user-service"
    team       = "infra"
    owner      = "team-leader"
    auto-stop  = "true"
    created-by = "terraform"
  }
}

resource "aws_instance" "k8s_worker_2" {
  #checkov:skip=CKV_AWS_88:Public IP is temporarily required for GitHub-hosted runner SSH; port 22 is limited to the runner IP /32 and revoked after the workflow.
  #checkov:skip=CKV2_AWS_41:This node does not call AWS APIs; attaching an IAM role would grant unnecessary permissions.
  ami                         = "ami-0c9c942bd7bf113a2"
  instance_type               = "t3.small"
  ebs_optimized               = true
  monitoring                  = true
  subnet_id                   = data.aws_subnet.public_a.id
  vpc_security_group_ids      = [data.aws_security_group.k8s.id]
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  tags = {
    Name       = "k8s-worker-2"
    service    = "user-service"
    team       = "infra"
    owner      = "team-leader"
    auto-stop  = "true"
    created-by = "terraform"
  }
}

resource "aws_instance" "k8s_worker_3" {
  #checkov:skip=CKV_AWS_88:Public IP is temporarily required for GitHub-hosted runner SSH; port 22 is limited to the runner IP /32 and revoked after the workflow.
  #checkov:skip=CKV2_AWS_41:This node does not call AWS APIs; attaching an IAM role would grant unnecessary permissions.
  ami                         = "ami-0c9c942bd7bf113a2"
  instance_type               = "t3.small"
  ebs_optimized               = true
  monitoring                  = true
  subnet_id                   = data.aws_subnet.public_a.id
  vpc_security_group_ids      = [data.aws_security_group.k8s.id]
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true

  root_block_device {
    encrypted = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "disabled"
  }

  tags = {
    Name       = "k8s-worker-3"
    service    = "user-service"
    team       = "infra"
    owner      = "team-leader"
    auto-stop  = "true"
    created-by = "terraform"
  }
}
