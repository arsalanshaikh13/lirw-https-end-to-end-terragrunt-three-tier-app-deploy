# Installation and Running Guide

## Overview

This repository contains Infrastructure as Code (IaC) for automated AWS resource provisioning and configuration using Terraform, Terragrunt, Ansible, and Packer.

**⚠️ Important Notice:**

- Initial deployment takes approximately **40 minutes**
- Resource cleanup takes approximately **20 minutes**
- All operations are logged in `logs/` and `ansible-logs/` directories (created automatically on startup)

---

## Prerequisites

### Required Software

Ensure the following tools are installed on your system:

| Tool           | Purpose                                   | Installation Link                                                                                     |
| -------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **AWS CLI**    | AWS credential management and API access  | [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)      |
| **Terraform**  | Infrastructure provisioning               | [Install Terraform](https://developer.hashicorp.com/terraform/downloads)                              |
| **Terragrunt** | Terraform wrapper for DRY configurations  | [Install Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/)                   |
| **jq**         | JSON processing in scripts                | [Install jq](https://stedolan.github.io/jq/download/)                                                 |
| **Packer**     | Machine image building                    | [Install Packer](https://developer.hashicorp.com/packer/downloads)                                    |
| **Ansible**    | Configuration management and provisioning | [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) |

### AWS Requirements

- **AWS Account** with appropriate permissions
- **Route 53 Hosted Zone** for your domain (required for DNS configuration)
- **IAM permissions** to create EC2 instances, VPCs, security groups, and other AWS resources

---

## Configuration

### 1. Configure AWS Credentials

Set up your AWS credentials using one of the following methods:

**Option A: AWS CLI Configure (Recommended)**

```bash
aws configure
```

**Option B: Environment Variables**

```bash
export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_DEFAULT_REGION="us-east-1"
```

**Option C: AWS Credentials File**

```bash
# ~/.aws/credentials
[default]
aws_access_key_id = your_access_key
aws_secret_access_key = your_secret_key
```

### 2. Update Configuration File

Edit the `terraform.tfvars` file with your specific configuration:

```hcl
# terraform.tfvars

# Domain Configuration (must be hosted on AWS Route 53)
certificate_domain_name   = "yourdomain.com"
additional_domain_name    = "{env}.yourdomain.com"    # Environment-specific subdomain
alb_api_domain_name       = "api.yourdomain.com"      # Internal load balancer endpoint

# EC2 Configuration
instance_type = "t4g.small"  # Default: runs on Amazon Linux 2 (ec2-user)
region        = "us-east-1"

# Add other configuration parameters as needed
```

**Domain Configuration Notes:**

- `certificate_domain_name`: Primary domain for SSL certificate
- `additional_domain_name`: Environment subdomain (replace `{env}` with dev, staging, prod, etc.)
- `alb_api_domain_name`: API endpoint for internal Application Load Balancer

**⚠️ Domain Requirement:** Your domain must be managed by AWS Route 53 before deployment.

---

## Usage

### Starting Infrastructure

Deploy all AWS resources:

```bash
./scripts/operation.sh startup
```

**What happens during startup:**

- Validates prerequisites and configuration
- Provisions AWS infrastructure via Terraform/Terragrunt
- Builds machine images with Packer
- Configures resources using Ansible
- Sets up DNS records in Route 53
- Creates log directories and begins logging

**Duration:** ~40 minutes

### Destroying Infrastructure

Clean up all AWS resources:

```bash
./scripts/operation.sh cleanup
```

**What happens during cleanup:**

- Removes all provisioned AWS resources
- Deletes DNS records
- Preserves logs for audit purposes

**Duration:** ~20 minutes

---

## Monitoring and Troubleshooting

### Log Files

All operations are logged for debugging and audit purposes:

```
project-root/
├── logs/
│   └── packer/
│       ├── backend/
│       │   ├── ansible-logs/      # Backend Ansible execution logs
│       │   └── packer-logs/       # Backend Packer build logs
│       └── frontend/
│           ├── ansible-logs/      # Frontend Ansible execution logs
│           └── packer-logs/       # Frontend Packer build logs
└── terraform_{env}/
    └── nat_key/
        └── key/
            └── key.pem            # SSH private key for EC2 access
```

**Note:** Log directories are created automatically when you run `./scripts/operation.sh startup`

### SSH Access for Debugging

To SSH into EC2 instances for debugging:

```bash
# Locate your environment-specific key
cd terraform_{env}/nat_key/key/

# Set correct permissions on the key file
chmod 400 key.pem

# SSH into your EC2 instance
ssh -i key.pem ec2-user@<instance-public-ip>
```

**Security Note:** The `key.pem` file contains sensitive credentials. Never commit this file to version control.

### Common Issues

**Issue:** "Domain not found in Route 53"

- **Solution:** Ensure your domain is hosted in Route 53 before running startup

**Issue:** "AWS credentials not configured"

- **Solution:** Run `aws configure` and verify credentials with `aws sts get-caller-identity`

**Issue:** "Permission denied on operation.sh"

- **Solution:** Make the script executable: `chmod +x ./scripts/operation.sh`

**Issue:** "Cannot SSH into EC2 instance"

- **Solution:** Ensure key.pem has correct permissions: `chmod 400 terraform_{env}/nat_key/key/key.pem`
- Verify security group allows SSH (port 22) from your IP address

**Issue:** "Packer build failures"

- **Solution:** Check logs in `logs/packer/backend/packer-logs/` or `logs/packer/frontend/packer-logs/`
- Verify Ansible playbooks completed successfully in corresponding ansible-logs directories

---

## Default Configuration

- **Operating System:** Amazon Linux 2023 arm64 (ec2-user)
- **Default Region:** us-east-1
- **Default Instance Type:** t4g.small
- **Logging:** Automatic (logs/ and ansible-logs/)

---

## Best Practices

1. **Review tfvars:** Always review `terraform.tfvars` before deployment
2. **Cost monitoring:** Monitor AWS costs during the 40-minute deployment
3. **Log retention:** Keep logs for troubleshooting and compliance
4. **Cleanup verification:** Verify all resources are destroyed via AWS Console after cleanup
5. **Version control:** Never commit sensitive files to version control:
   - `terraform.tfvars` (may contain sensitive data)
   - `terraform_{env}/nat_key/key/key.pem` (SSH private keys)
   - Any files in `.gitignore`
6. **Key management:** Store SSH keys securely and rotate regularly
7. **Environment separation:** Use different domain names for dev/staging/prod environments

---

## Support and Contribution

For issues, questions, or contributions, please:

- Open an issue in the repository
- Review existing documentation in the `docs/` directory
- Contact the maintainer team

---

## License

[Add your license information here]

---

**⏱️ Time Investment Summary:**

- Initial Setup: 10 minutes
- Deployment: 40 minutes
- Cleanup: 20 minutes
- **Total:** ~70 minutes for complete lifecycle
