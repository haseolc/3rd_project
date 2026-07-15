variable "osaka_master_ami_id" {
  description = "Cross-region copied Kubernetes master AMI in Osaka"
  type        = string
  default     = "ami-0ccda52359541cae5"
}

# ============================================================
# VPC
# 기본 태그:
# environment = prod-dr
# team        = infra
# service     = shared-network
# owner       = team-2
# auto-stop   = false
# created-by  = terraform
# ============================================================

resource "aws_vpc" "dr_vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

# ============================================================
# Public Subnets
# ============================================================

resource "aws_subnet" "dr_public_a" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "ap-northeast-3a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "dr_public_b" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "ap-northeast-3b"
  map_public_ip_on_launch = true
}

# ============================================================
# Internet Gateway
# ============================================================

resource "aws_internet_gateway" "dr_igw" {
  vpc_id = aws_vpc.dr_vpc.id
}

# ============================================================
# Route Table
# ============================================================

resource "aws_route_table" "dr_public_rt" {
  vpc_id = aws_vpc.dr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr_igw.id
  }
}

resource "aws_route_table_association" "dr_public_a" {
  subnet_id      = aws_subnet.dr_public_a.id
  route_table_id = aws_route_table.dr_public_rt.id
}

resource "aws_route_table_association" "dr_public_b" {
  subnet_id      = aws_subnet.dr_public_b.id
  route_table_id = aws_route_table.dr_public_rt.id
}

# ============================================================
# EC2 Key Pair
# service = shared-network 기본 태그 사용
# ============================================================

resource "aws_key_pair" "dr_key" {
  key_name   = "k8s-dr-osaka-key"
  public_key = file("/home/ubuntu/.ssh/id_rsa.pub")
}

# ============================================================
# Kubernetes Security Group
# service = shared-network 기본 태그 사용
# ============================================================

resource "aws_security_group" "dr_master_sg" {
  name        = "osaka-dr-master-sg"
  description = "Security group for Osaka DR Kubernetes master"
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API inside DR VPC"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    description = "Internal communication inside DR VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================================================
# Kubernetes Control Plane
# EC2와 Root EBS를 user-service로 분류
# ============================================================

resource "aws_instance" "dr_master" {
  ami                         = var.osaka_master_ami_id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.dr_public_a.id
  vpc_security_group_ids      = [aws_security_group.dr_master_sg.id]
  key_name                    = aws_key_pair.dr_key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "k8s-master-dr-osaka"
    Role    = "control-plane-dr"
    service = "user-service"
  }

  volume_tags = {
    environment = "prod-dr"
    team        = "infra"
    service     = "user-service"
    owner       = "team-2"
    auto-stop   = "false"
    created-by  = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================
# Kubernetes Worker 1
# ============================================================

resource "aws_instance" "dr_worker_1" {
  ami                         = var.osaka_master_ami_id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.dr_public_a.id
  vpc_security_group_ids      = [aws_security_group.dr_master_sg.id]
  key_name                    = aws_key_pair.dr_key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "k8s-worker-1-dr-osaka"
    Role    = "worker-dr"
    service = "user-service"
  }

  volume_tags = {
    environment = "prod-dr"
    team        = "infra"
    service     = "user-service"
    owner       = "team-2"
    auto-stop   = "false"
    created-by  = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================
# Kubernetes Worker 2
# ============================================================

resource "aws_instance" "dr_worker_2" {
  ami                         = var.osaka_master_ami_id
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.dr_public_b.id
  vpc_security_group_ids      = [aws_security_group.dr_master_sg.id]
  key_name                    = aws_key_pair.dr_key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name    = "k8s-worker-2-dr-osaka"
    Role    = "worker-dr"
    service = "user-service"
  }

  volume_tags = {
    environment = "prod-dr"
    team        = "infra"
    service     = "user-service"
    owner       = "team-2"
    auto-stop   = "false"
    created-by  = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# ============================================================
# Outputs
# ============================================================

output "dr_master_instance_id" {
  description = "Osaka DR Kubernetes master instance ID"
  value       = aws_instance.dr_master.id
}

output "dr_master_public_ip" {
  description = "Osaka DR Kubernetes master public IP"
  value       = aws_instance.dr_master.public_ip
}

output "dr_master_private_ip" {
  description = "Osaka DR Kubernetes master private IP"
  value       = aws_instance.dr_master.private_ip
}

output "dr_vpc_id" {
  description = "Osaka DR VPC ID"
  value       = aws_vpc.dr_vpc.id
}

output "dr_worker_1_public_ip" {
  description = "Osaka DR worker 1 public IP"
  value       = aws_instance.dr_worker_1.public_ip
}

output "dr_worker_1_private_ip" {
  description = "Osaka DR worker 1 private IP"
  value       = aws_instance.dr_worker_1.private_ip
}

output "dr_worker_2_public_ip" {
  description = "Osaka DR worker 2 public IP"
  value       = aws_instance.dr_worker_2.public_ip
}

output "dr_worker_2_private_ip" {
  description = "Osaka DR worker 2 private IP"
  value       = aws_instance.dr_worker_2.private_ip
}
