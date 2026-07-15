locals {
  seoul_rds_arn = "arn:aws:rds:ap-northeast-2:416170614736:db:project-postgres-db"
}

resource "aws_db_subnet_group" "dr_rds_subnet_group" {
  name        = "osaka-dr-rds-subnet-group"
  description = "RDS subnet group for Osaka DR"

  subnet_ids = [
    aws_subnet.dr_public_a.id,
    aws_subnet.dr_public_b.id
  ]

  tags = {
    Name      = "osaka-dr-rds-subnet-group"
    service   = "db"
    auto-stop = "false"
  }
}

resource "aws_security_group" "dr_rds_sg" {
  name        = "osaka-dr-rds-sg"
  description = "Allow PostgreSQL access from Osaka DR Kubernetes nodes"
  vpc_id      = aws_vpc.dr_vpc.id

  ingress {
    description     = "PostgreSQL from Osaka Kubernetes nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.dr_master_sg.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "osaka-dr-rds-sg"
    service   = "db"
    auto-stop = "false"
  }
}

resource "aws_db_instance" "dr_postgres_replica" {
  identifier = "project-postgres-db-osaka-dr"

  # Cross-Region Replica에서는 원본 리전의 RDS ARN을 사용
  replicate_source_db = local.seoul_rds_arn

  instance_class = "db.t3.micro"
  storage_type   = "gp3"

  db_subnet_group_name   = aws_db_subnet_group.dr_rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.dr_rds_sg.id]

  publicly_accessible = false
  multi_az            = false

  # Replica 자체의 자동 백업
  backup_retention_period = 7
  copy_tags_to_snapshot   = true

  deletion_protection       = true
  skip_final_snapshot       = false
  final_snapshot_identifier = "project-postgres-db-osaka-dr-final"

  auto_minor_version_upgrade = true

  tags = {
    Name      = "project-postgres-db-osaka-dr"
    service   = "db"
    auto-stop = "false"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    aws_db_subnet_group.dr_rds_subnet_group,
    aws_security_group.dr_rds_sg
  ]
}

output "dr_rds_identifier" {
  description = "Osaka DR RDS identifier"
  value       = aws_db_instance.dr_postgres_replica.identifier
}

output "dr_rds_endpoint" {
  description = "Osaka DR RDS endpoint"
  value       = aws_db_instance.dr_postgres_replica.address
}

output "dr_rds_port" {
  description = "Osaka DR RDS port"
  value       = aws_db_instance.dr_postgres_replica.port
}

output "dr_rds_status" {
  description = "Osaka DR RDS status"
  value       = aws_db_instance.dr_postgres_replica.status
}
