resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-sg"
  description = "Kubernetes Security Group"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 4789
    to_port     = 4789
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["192.168.0.0/16"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-sg"
  }
}

resource "aws_key_pair" "k8s_key" {
  key_name   = "k8s-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCzF9Hnf895nUIr/B3pM5qmpuItc24KXQSh/2m9/imLv/fh+9xDO8FqGWs7bLJCi2IkXbJSnIi8nWnZx/FUyL5+YTb75eQPFVF5x5QfPOIky7Y7zZwjElDqqiq+djU5jbYaULlY8uGsaez56tZn5uoP6ses3KpuKuCRs7pTJf46DFwM2KNcWKuub4P0nVFQGeNjWpY9+DNDg/Hnxlo1SM0H/B6bXXyuSHjOtIxBOWr4MIJZ9yR1dduH8GVab8PVU8CaR1F+PlZt9jseDNS4V6Bt7R4ME76qVdM22o6+hnUfTZ8Z3uq7pAoZe3WI9SUPV0+Z7PJsbg4R+LF/Ly2OJjlHqZddInKHX4ENnHDFxwZR5BX1/Gk6QzYyR5Ges4Eqv8CvsP1LSjHHRmVLNL244/EOCuuZeUVp4J5+EwhEHTdKgiygcXsteJB84zwBYNj/o3+3KXib2GAUdZ3u60xKfIkz+9C7tOQbcz1nSWqOKV+Qb05hAxr5PtDHM1hzpZQc5tgkBlLJIPpyID8Pn+YOWdu3eDzDcCLitQA7l507rCub1k2sJb0EiqxpCfSskekk6LSq3ez9ClXYbk4F57fN7lc/ibDWPCnMMXmSbQLaZ10PSX7/tFwabmVegxcKdH6hYnkwKfaxmX7XsU97qbD5d3O+DkgDHPD+JlRkl/qq5rHKmw== ubuntu@ubuntu-2204"
}

resource "aws_instance" "k8s_master" {
  ami                         = "ami-0c9c942bd7bf113a2"
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true

  tags = {
    Name       = "k8s-master"
    service    = "user-service"
    team       = "infra"
    owner      = "team-leader"
    auto-stop  = "true"
    created-by = "terraform"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_instance" "k8s_worker_1" {
  ami                         = "ami-0c9c942bd7bf113a2"
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true

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
  ami                         = "ami-0c9c942bd7bf113a2"
  instance_type               = "t3.small"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.k8s_sg.id]
  key_name                    = aws_key_pair.k8s_key.key_name
  associate_public_ip_address = true

  tags = {
    Name       = "k8s-worker-2"
    service    = "user-service"
    team       = "infra"
    owner      = "team-leader"
    auto-stop  = "true"
    created-by = "terraform"
  }
}
