resource "aws_security_group" "dr_alb_sg" {
  name        = "osaka-dr-alb-sg"
  description = "Security group for Osaka DR ALB"
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # provider default_tags 적용:
  # environment = prod-dr
  # team        = infra
  # service     = shared-network
  # owner       = team-2
  # auto-stop   = false
  # created-by  = terraform
}

resource "aws_security_group_rule" "dr_nodes_from_alb" {
  type                     = "ingress"
  description              = "Allow ALB to access Kubernetes NodePort"
  from_port                = 30080
  to_port                  = 30080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.dr_master_sg.id
  source_security_group_id = aws_security_group.dr_alb_sg.id
}

resource "aws_lb" "dr_alb" {
  name               = "osaka-dr-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.dr_alb_sg.id]

  subnets = [
    aws_subnet.dr_public_a.id,
    aws_subnet.dr_public_b.id
  ]

  tags = {
    service   = "user-service"
    auto-stop = "false"
  }
}

resource "aws_lb_target_group" "dr_tg" {
  name        = "osaka-dr-tg"
  port        = 30080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.dr_vpc.id
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
    service   = "user-service"
    auto-stop = "false"
  }
}

resource "aws_lb_target_group_attachment" "dr_worker_1" {
  target_group_arn = aws_lb_target_group.dr_tg.arn
  target_id        = aws_instance.dr_worker_1.id
  port             = 30080
}

resource "aws_lb_target_group_attachment" "dr_worker_2" {
  target_group_arn = aws_lb_target_group.dr_tg.arn
  target_id        = aws_instance.dr_worker_2.id
  port             = 30080
}

resource "aws_lb_listener" "dr_http" {
  load_balancer_arn = aws_lb.dr_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dr_tg.arn
  }
}

output "dr_alb_dns_name" {
  description = "Osaka DR ALB DNS name"
  value       = aws_lb.dr_alb.dns_name
}

output "dr_target_group_arn" {
  description = "Osaka DR target group ARN"
  value       = aws_lb_target_group.dr_tg.arn
}
