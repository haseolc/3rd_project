output "vpc_id" {
  value = data.aws_vpc.shared.id
}

output "public_subnet_id" {
  value = data.aws_subnet.public_a.id
}

output "security_group_id" {
  value = data.aws_security_group.k8s.id
}

output "master_instance_id" {
  value = aws_instance.k8s_master.id
}

output "worker_1_instance_id" {
  value = aws_instance.k8s_worker_1.id
}

output "worker_2_instance_id" {
  value = aws_instance.k8s_worker_2.id
}

output "worker_3_instance_id" {
  value = aws_instance.k8s_worker_3.id
}

output "master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "worker_1_public_ip" {
  value = aws_instance.k8s_worker_1.public_ip
}

output "worker_2_public_ip" {
  value = aws_instance.k8s_worker_2.public_ip
}

output "worker_3_public_ip" {
  value = aws_instance.k8s_worker_3.public_ip
}

output "k8s_public_ips" {
  value = {
    master   = aws_instance.k8s_master.public_ip
    worker_1 = aws_instance.k8s_worker_1.public_ip
    worker_2 = aws_instance.k8s_worker_2.public_ip
    worker_3 = aws_instance.k8s_worker_3.public_ip
  }
}

output "k8s_private_ips" {
  value = {
    master   = aws_instance.k8s_master.private_ip
    worker_1 = aws_instance.k8s_worker_1.private_ip
    worker_2 = aws_instance.k8s_worker_2.private_ip
    worker_3 = aws_instance.k8s_worker_3.private_ip
  }
}

output "master_ssh_command" {
  value = "ssh -i ~/.ssh/k8s-key.pem ubuntu@${aws_instance.k8s_master.public_ip}"
}

output "smoke_alb_dns_name" {
  description = "Persistent Kubernetes ALB DNS name"
  value       = data.aws_lb.k8s.dns_name
}

output "smoke_alb_url" {
  description = "Persistent Kubernetes ALB URL"
  value       = "http://${data.aws_lb.k8s.dns_name}"
}
