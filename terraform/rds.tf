resource "aws_db_subnet_group" "rds_subnet_group" {
  name = "project-rds-subnet-group"

  subnet_ids = [
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet_b.id,
  ]

  tags = {
    Name    = "project-rds-subnet-group"
    service = "user-service"
    owner   = "team-2"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for PostgreSQL RDS"

  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "rds-sg"
    service = "user-service"
    owner   = "team-2"
  }
}

#checkov:skip=CKV_AWS_293:Sandbox infrastructure must support the controlled manual destroy workflow.
resource "aws_db_instance" "project_db" {
  identifier     = "project-postgres-db"
  engine         = "postgres"
  engine_version = "16"
  instance_class = "db.t3.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name                     = "projectdb"
  username                    = "postgres"
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids      = [aws_security_group.rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
  # Sandbox infrastructure must support the manual destroy workflow.
  deletion_protection     = false
  backup_retention_period = 7
  copy_tags_to_snapshot   = true

  tags = {
    Name       = "project-postgres-db"
    service    = "user-service"
    team       = "infra"
    owner      = "team-2"
    auto-stop  = "true"
    created-by = "terraform"
  }
}
