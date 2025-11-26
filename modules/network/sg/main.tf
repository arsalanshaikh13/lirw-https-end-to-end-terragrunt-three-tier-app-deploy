resource "aws_security_group" "alb_sg" {
  name        = "alb security group"
  description = "enable http/https access on port 80/443"
  vpc_id      = var.vpc_id

  ingress {
    description = "http access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb_sg"
    Environment = var.environment

  }
}

# create security group for the Client
resource "aws_security_group" "client_sg" {
  name        = "client_sg"
  description = "enable http/https access on port 80 for client sg"
  vpc_id      = var.vpc_id

  ingress {
    description     = "http access"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "custom ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Client_sg"
    Environment = var.environment
  }
  depends_on = [aws_security_group.alb_sg]

}
# create security group for the internal alb
resource "aws_security_group" "internal_alb_sg" {
  name        = "internal_alb_sg"
  description = "enable http/https access on port 80 for internal alb sg"
  vpc_id      = var.vpc_id

  ingress {
    description     = "http access"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.client_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "internal_alb_sg"
    Environment = var.environment
  }

  depends_on = [aws_security_group.client_sg]

}
# create security group for the Server app
resource "aws_security_group" "server_sg" {
  name = "server_sg"
  # description = "enable http/https access on port 3200 for server app sg"
  description = var.server_sg_desc
  vpc_id      = var.vpc_id

  ingress {
    description = "custom tcp access"
    from_port   = var.server_port
    # from_port       = 3200
    to_port = var.server_port
    # to_port         = 3200
    protocol        = "tcp"
    security_groups = [aws_security_group.internal_alb_sg.id]
  }
  ingress {
    description = "custom ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "server_sg"
    Environment = var.environment
  }

  depends_on = [aws_security_group.internal_alb_sg]
}

# create security group for the Database
resource "aws_security_group" "db_sg" {
  name = "db_sg"
  # description = "enable mysql access on port 3306 from server-sg"
  description = var.db_sg_desc
  vpc_id      = var.vpc_id

  ingress {
    description = var.db_inbound_desc
    # description     = "mysql access"
    # from_port       = 3306
    # to_port         = 3306
    from_port       = var.db_security_port
    to_port         = var.db_security_port
    protocol        = "tcp"
    security_groups = [aws_security_group.server_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "database_sg"
    Environment = var.environment
  }

  depends_on = [aws_security_group.server_sg]

}