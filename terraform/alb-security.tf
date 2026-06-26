resource "aws_security_group" "smoke_alb" {
  #checkov:skip=CKV_AWS_260:Internet-facing ALB requires HTTP access for the sandbox WAF validation; Kubernetes nodes allow NodePort traffic only from this ALB security group.
  name        = "smoke-alb-sg"
  description = "Security group for the smoke test Application Load Balancer"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "Public HTTP access protected by AWS WAF"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Forward traffic to the Kubernetes smoke NodePort"
    from_port   = 30080
    to_port     = 30080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  tags = {
    Name       = "smoke-alb-sg"
    purpose    = "waf-entrypoint"
    created-by = "terraform"
  }
}
