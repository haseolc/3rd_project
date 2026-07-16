resource "aws_lb_target_group_attachment" "worker_1" {
  target_group_arn = data.aws_lb_target_group.k8s_ingress.arn
  target_id        = aws_instance.k8s_worker_1.id
  port             = 30080
}

resource "aws_lb_target_group_attachment" "worker_2" {
  target_group_arn = data.aws_lb_target_group.k8s_ingress.arn
  target_id        = aws_instance.k8s_worker_2.id
  port             = 30080
}

resource "aws_lb_target_group_attachment" "worker_3" {
  target_group_arn = data.aws_lb_target_group.k8s_ingress.arn
  target_id        = aws_instance.k8s_worker_3.id
  port             = 30080
}
