region                  = "us-east-1"
project_name            = "lirw-app"
#choose environment
environment = "dev"
# vpc variables 
vpc_cidr                = "10.0.0.0/16"
pub_sub_1a_cidr         = "10.0.1.0/24"
pub_sub_2b_cidr         = "10.0.2.0/24"
pri_sub_3a_cidr         = "10.0.3.0/24"
pri_sub_4b_cidr         = "10.0.4.0/24"
pri_sub_5a_cidr         = "10.0.5.0/24"
pri_sub_6b_cidr         = "10.0.6.0/24"
pri_sub_7a_cidr         = "10.0.7.0/24"
pri_sub_8b_cidr         = "10.0.8.0/24"

# security group 
server_port = 3200
server_sg_desc = "enable http/https access on port 3200 for server app sg"
db_security_port = 3306
db_inbound_desc = "mysql access"
db_sg_desc = "enable mysql access on port 3306 from server-sg"


# nat instance related variables
# nat_instance_count = 1
nat_ami_type = "al2023-ami-2023.*-arm64"
nat_ami_virtualization_type = "hvm"
nat_ami_owner = "amazon"
nat_instance_type = "t4g.small" # 750 hrs free / month till dec 31 2025
nat_volume_type = "standard"
nat_volume_size = 8

flow_log_bucket_name = "vpc-flow-log-s3-bucket-lirw"
# acm config
acm_validation_method = "DNS"
# backend tfstate bootstrapping variables
bucket_name             = "lirw-app-bucket-terragrunt"
backend_bucket_name = "lirw-backend"
dynamodb_table      = "lirw-lock-table"

# Database values which is to pass on to the rds and apps
db_username             = "admin_3_tier"
db_password             = "Asd1-CaPQ22"
db_name                 = "lirw_react_node_app"
db_port                 = "3306"

# only specific to rds
db_engine = "mysql"
db_identifier = "lirw-dev-db"
db_instance_type = "db.t4g.micro"
db_version = "8.0.42"
db_storage_volume = 20
db_storage_type = "standard"
db_sub_name = "lirw-db-subnet-a-b"
retention_period = 0

# asg variables
max_size = 1
min_size = 1
desired_cap = 1
asg_health_check_type = "ELB" #"ELB" or default EC2

# asg and null resource variables combined
backend_ami_type = "al2023-ami-2023.*-arm64"
frontend_ami_type = "al2023-ami-2023.*-arm64"
backend_instance_type =  "t4g.small" # free tier till 31st dec/2025
frontend_instance_type =  "t4g.small" # free tier till 31st dec/2025
frontend_volume_type = "standard"
frontend_volume_size = 8
backend_volume_type = "standard"
backend_volume_size = 8
ssh_username = "ec2-user"
ssh_interface = "session_manager" # or "public_ip"
backend_ami_name = "three-tier-backend"
frontend_ami_name = "three-tier-frontend"

# waf configuration
block_ip_set_name = "block-ip-set1"
block_ip_set_description =  "IP Set for blocking specific IPs"
block_ipset_scope = "CLOUDFRONT" # or "REGIONAL"
ip_address_version = "IPV4" # or "IPV6"
ip_addresses = [ "103.179.122.6/32", "203.187.235.23/32", "203.187.202.1/32" , "123.201.94.92/32", "45.117.74.38/32" ]
cloudfront_waf_name = "cloudfront-waf-ipset-badip-iplimit"
cloudfront_waf_description = "Web ACL with IP Set rule"
cloudfront_waf_scope = "CLOUDFRONT" # Must match the IP Set's scope
alb_waf_name = "alb-waf-customHeader-sqli-xss"
alb_waf_scope = "REGIONAL"
alb_waf_description = "Minimal WAF: only CloudFront header allowed - block simple SQLi and  XSS"

# cloudfront custom header
cloudfront_custom_header_name = "X-Custom-Header"
cloudfront_custom_header_value = "random-value-123456"

# domain records
certificate_domain_name = "devsandbox.space"
additional_domain_name  = "www.devsandbox.space"
alb_api_domain_name     = "api.devsandbox.space"

# sns topic email address
email_address = ["ars786sh@gmail.com"]