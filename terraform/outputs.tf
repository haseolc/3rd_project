output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_id" {
  description = "Public Subnet ID"
  value       = aws_subnet.public_subnet.id
}

output "security_group_id" {
  description = "Kubernetes Security Group ID"
  value       = aws_security_group.k8s_sg.id
}

output "master_instance_id" {
  description = "Kubernetes master EC2 instance ID"
  value       = aws_instance.k8s_master.id
}

output "worker_1_instance_id" {
  description = "Kubernetes worker-1 EC2 instance ID"
  value       = aws_instance.k8s_worker_1.id
}

output "worker_2_instance_id" {
  description = "Kubernetes worker-2 EC2 instance ID"
  value       = aws_instance.k8s_worker_2.id
}

output "master_public_ip" {
  description = "Kubernetes master public IP"
  value       = aws_instance.k8s_master.public_ip
}

output "worker_1_public_ip" {
  description = "Kubernetes worker-1 public IP"
  value       = aws_instance.k8s_worker_1.public_ip
}

output "worker_2_public_ip" {
  description = "Kubernetes worker-2 public IP"
  value       = aws_instance.k8s_worker_2.public_ip
}

output "master_private_ip" {
  description = "Kubernetes master private IP"
  value       = aws_instance.k8s_master.private_ip
}

output "worker_1_private_ip" {
  description = "Kubernetes worker-1 private IP"
  value       = aws_instance.k8s_worker_1.private_ip
}

output "worker_2_private_ip" {
  description = "Kubernetes worker-2 private IP"
  value       = aws_instance.k8s_worker_2.private_ip
}

output "k8s_public_ips" {
  description = "Public IPs of Kubernetes nodes"
  value = {
    master   = aws_instance.k8s_master.public_ip
    worker_1 = aws_instance.k8s_worker_1.public_ip
    worker_2 = aws_instance.k8s_worker_2.public_ip
  }
}

output "k8s_private_ips" {
  description = "Private IPs of Kubernetes nodes"
  value = {
    master   = aws_instance.k8s_master.private_ip
    worker_1 = aws_instance.k8s_worker_1.private_ip
    worker_2 = aws_instance.k8s_worker_2.private_ip
  }
}

output "master_ssh_command" {
  description = "SSH command for Kubernetes master node"
  value       = "ssh -i ~/.ssh/k8s-key.pem ubuntu@${aws_instance.k8s_master.public_ip}"
}

output "monitoring_access_note" {
  description = "Secure access method for Grafana and Prometheus"
  value       = "Monitoring services use ClusterIP. Connect to the master through temporary SSH access and use kubectl port-forward."
}
