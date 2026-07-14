variable "osaka_master_ami_id" {
  description = "Cross-region copied Kubernetes master AMI in Osaka"
  type        = string
  default     = "ami-0ccda52359541cae5"
}

resource "aws_vpc" "dr_vpc" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "osaka-dr-vpc"
  }
}

resource "aws_subnet" "dr_public_a" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "ap-northeast-3a"
  map_public_ip_on_launch = true

  tags = {
    Name = "osaka-dr-public-a"
  }
}

resource "aws_subnet" "dr_public_b" {
  vpc_id                  = aws_vpc.dr_vpc.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "ap-northeast-3b"
  map_public_ip_on_launch = true

  tags = {
    Name = "osaka-dr-public-b"
  }
}

resource "aws_internet_gateway" "dr_igw" {
  vpc_id = aws_vpc.dr_vpc.id

  tags = {
    Name = "osaka-dr-igw"
  }
}

resource "aws_route_table" "dr_public_rt" {
  vpc_id = aws_vpc.dr_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dr_igw.id
  }

  tags = {
    Name = "osaka-dr-public-rt"
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

resource "aws_key_pair" "dr_key" {
  key_name   = "k8s-dr-osaka-key"
  public_key = file("/home/ubuntu/.ssh/id_rsa.pub")
}

resource "aws_security_group" "dr_master_sg" {
  name        = "osaka-dr-master-sg"
  description = "Security group for Osaka DR Kubernetes master"
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Kubernetes API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    description = "Internal DR VPC communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "osaka-dr-master-sg"
  }
}

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
    Name = "k8s-master-dr-osaka"
    Role = "control-plane-dr"
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "dr_master_instance_id" {
  value = aws_instance.dr_master.id
}

output "dr_master_public_ip" {
  value = aws_instance.dr_master.public_ip
}

output "dr_master_private_ip" {
  value = aws_instance.dr_master.private_ip
}

output "dr_vpc_id" {
  value = aws_vpc.dr_vpc.id
}
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
    Name = "k8s-worker-1-dr-osaka"
    Role = "worker-dr"
  }

  lifecycle {
    prevent_destroy = true
  }
}

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
    Name = "k8s-worker-2-dr-osaka"
    Role = "worker-dr"
  }

  lifecycle {
    prevent_destroy = true
  }
}

output "dr_worker_1_public_ip" {
  value = aws_instance.dr_worker_1.public_ip
}

output "dr_worker_1_private_ip" {
  value = aws_instance.dr_worker_1.private_ip
}

output "dr_worker_2_public_ip" {
  value = aws_instance.dr_worker_2.public_ip
}

output "dr_worker_2_private_ip" {
  value = aws_instance.dr_worker_2.private_ip
}
