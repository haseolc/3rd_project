resource "aws_lb" "smoke" {
  #checkov:skip=CKV2_AWS_76:The associated Web ACL includes AWSManagedRulesKnownBadInputsRuleSet with Log4JRCE protections; the direct WAF Log4j check passes.
  #checkov:skip=CKV2_AWS_20:This ephemeral sandbox has no domain or ACM certificate; HTTP is used only for temporary WAF validation and must be replaced by HTTPS in production.
  #checkov:skip=CKV_AWS_150:Deletion protection is intentionally disabled because the sandbox infrastructure must be removable through the controlled destroy workflow.
  name               = "3rd-project-smoke-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    aws_security_group.smoke_alb.id,
  ]

  subnets = [
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet_b.id,
  ]

  drop_invalid_header_fields = true
  enable_deletion_protection = false

  access_logs {
    bucket  = "sagal-3rd-project-audit-logs-${data.aws_caller_identity.current.account_id}-ap-northeast-2"
    prefix  = "alb"
    enabled = true
  }

  tags = {
    Name       = "3rd-project-smoke-alb"
    purpose    = "waf-entrypoint"
    created-by = "terraform"
  }
}

resource "aws_lb_target_group" "smoke" {
  #checkov:skip=CKV_AWS_378:Backend HTTP is restricted to the VPC and the Kubernetes NodePort accepts traffic only from the ALB security group.
  name        = "3rd-project-smoke-tg"
  port        = 30080
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main_vpc.id

  deregistration_delay = 30

  health_check {
    enabled             = true
    protocol            = "HTTP"
    port                = "traffic-port"
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name       = "3rd-project-smoke-tg"
    purpose    = "smoke-nodeport"
    created-by = "terraform"
  }
}

resource "aws_lb_target_group_attachment" "smoke_worker_1" {
  target_group_arn = aws_lb_target_group.smoke.arn
  target_id        = aws_instance.k8s_worker_1.id
  port             = 30080
}

resource "aws_lb_target_group_attachment" "smoke_worker_2" {
  target_group_arn = aws_lb_target_group.smoke.arn
  target_id        = aws_instance.k8s_worker_2.id
  port             = 30080
}

resource "aws_lb_listener" "smoke_http" {
  #checkov:skip=CKV_AWS_2:This ephemeral sandbox has no domain or ACM certificate; the public HTTP listener exists only for temporary WAF validation.
  #checkov:skip=CKV_AWS_103:TLS policy is not applicable to this temporary HTTP listener; production must use an HTTPS listener with TLS 1.2 or later.
  load_balancer_arn = aws_lb.smoke.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.smoke.arn
  }
}
