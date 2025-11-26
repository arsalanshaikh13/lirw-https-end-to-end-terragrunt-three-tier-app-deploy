# Creating VPC Endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "cloudwatch-logs-endpoint-sg"
  description = "Security group for CloudWatch Logs VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project_name}-vpc_endpoint_sg"
    Environment = var.environment
  }
}

# CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.pri_sub_5a_id, var.pri_sub_6b_id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-cw-logs-endpoint"
    Environment = var.environment
  }
}

# # CloudWatch Metrics
# resource "aws_vpc_endpoint" "monitoring" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${var.region}.monitoring"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
# }

# SSM (for Parameter Store & Session Manager)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.pri_sub_5a_id, var.pri_sub_6b_id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true

  tags = {
    Name        = "${var.project_name}-ssm-endpoint"
    Environment = var.environment
  }
}


# # SSM Messages (for Session Manager)
# resource "aws_vpc_endpoint" "ssmmessages" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${var.region}.ssmmessages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
# }

# # EC2 Messages (for SSM Agent)
# resource "aws_vpc_endpoint" "ec2messages" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${var.region}.ec2messages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
# }

resource "aws_vpc_endpoint" "s3_gateway_vpc_flow_logs" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    var.pri_rt_a_id,
    var.pri_rt_b_id
  ]

  tags = {
    Name        = "${var.project_name}-s3-endpoint"
    Environment = var.environment
  }
}



# ## Quick Decision Tree
# ```
# Do you need custom metrics (memory, disk usage)?
# ├─ NO → No VPC endpoints needed (basic metrics work automatically)
# └─ YES → Need VPC endpoints for:
#     ├─ logs (if sending logs)
#     ├─ monitoring (if sending custom metrics)
#     └─ ssm* (if using Parameter Store or Session Manager)
