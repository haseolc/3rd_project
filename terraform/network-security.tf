resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main-default-sg-restricted"
  }
}
