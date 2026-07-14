# ============================================================
# Existing Kubernetes VPC resources
# ============================================================

data "aws_vpc" "k8s_existing_vpc" {
  id = "vpc-09b2f47da0466ba08"
}

data "aws_subnet" "k8s_public_subnet_a" {
  id = "subnet-0e79d7a2dee8ec9f3"
}

data "aws_subnet" "k8s_public_subnet_b" {
  id = "subnet-0faf6bea039c8f143"
}

data "aws_security_group" "k8s_node_sg" {
  id = "sg-02cfb946649a50d91"
}

# ============================================================
# ALB Security Group
# ============================================================

resource "aws_security_group" "k8s_alb_v2_sg" {
  name        = "k8s-alb-v2-sg"
  description = "Security group for Kubernetes ALB in existing cluster VPC"
  vpc_id      = data.aws_vpc.k8s_existing_vpc.id

  ingress {
    description = "HTTP access to ALB"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description     = "ALB to Kubernetes NodePort"
    from_port       = 30080
    to_port         = 30080
    protocol        = "tcp"
    security_groups = [data.aws_security_group.k8s_node_sg.id]
  }

  tags = {
    Name       = "k8s-alb-v2-sg"
    service    = "user-service"
    team       = "infra"
    owner      = "team-2"
    created-by = "terraform"
  }
}

# 기존 노드 SG에 새 ALB SG의 NodePort 접근 허용
resource "aws_security_group_rule" "k8s_nodes_from_alb_v2" {
  type                     = "ingress"
  description              = "NodePort 30080 access from Kubernetes ALB v2"
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "tcp"
  security_group_id        = data.aws_security_group.k8s_node_sg.id
  source_security_group_id = aws_security_group.k8s_alb_v2_sg.id
}

# ============================================================
# Application Load Balancer
# ============================================================

resource "aws_lb" "k8s_alb_v2" {
  name               = "k8s-alb-v2"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.k8s_alb_v2_sg.id
  ]

  subnets = [
    data.aws_subnet.k8s_public_subnet_a.id,
    data.aws_subnet.k8s_public_subnet_b.id
  ]

  tags = {
    Name       = "k8s-alb-v2"
    service    = "user-service"
    team       = "infra"
    owner      = "team-2"
    created-by = "terraform"
  }
}

# ============================================================
# Target Group
# ============================================================

resource "aws_lb_target_group" "k8s_ingress_tg_v2" {
  name        = "k8s-ingress-tg-v2"
  port        = 30080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.k8s_existing_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    port                = "traffic-port"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name       = "k8s-ingress-tg-v2"
    service    = "user-service"
    team       = "infra"
    owner      = "team-2"
    created-by = "terraform"
  }
}

# ============================================================
# Listener
# ============================================================

resource "aws_lb_listener" "k8s_http_listener_v2" {
  load_balancer_arn = aws_lb.k8s_alb_v2.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.k8s_ingress_tg_v2.arn
  }
}

# ============================================================
# Worker Target Attachments
# ============================================================

resource "aws_lb_target_group_attachment" "k8s_worker_1_v2" {
  target_group_arn = aws_lb_target_group.k8s_ingress_tg_v2.arn
  target_id        = data.aws_instance.existing_worker_1.id
  port             = 30080
}

resource "aws_lb_target_group_attachment" "k8s_worker_2_v2" {
  target_group_arn = aws_lb_target_group.k8s_ingress_tg_v2.arn
  target_id        = data.aws_instance.existing_worker_2.id
  port             = 30080
}

resource "aws_lb_target_group_attachment" "k8s_worker_3_v2" {
  target_group_arn = aws_lb_target_group.k8s_ingress_tg_v2.arn
  target_id        = data.aws_instance.existing_worker_3.id
  port             = 30080
}

# ============================================================
# Outputs
# ============================================================

output "k8s_alb_v2_dns_name" {
  description = "DNS name of the ALB connected to the Kubernetes cluster VPC"
  value       = aws_lb.k8s_alb_v2.dns_name
}

output "k8s_target_group_v2_arn" {
  description = "ARN of the Kubernetes v2 target group"
  value       = aws_lb_target_group.k8s_ingress_tg_v2.arn
}

data "aws_instance" "existing_worker_1" {
  instance_id = "i-0ef2863c4d145c5a2"
}

data "aws_instance" "existing_worker_2" {
  instance_id = "i-0d58c354bd2948d09"
}

data "aws_instance" "existing_worker_3" {
  instance_id = "i-0e761d6fe7db810ed"
}
