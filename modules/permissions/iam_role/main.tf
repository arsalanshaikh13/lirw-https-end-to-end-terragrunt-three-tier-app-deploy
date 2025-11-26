# iam role and policy for S3 and SSM
# resource "aws_iam_role" "s3_ssm_role" {
resource "aws_iam_role" "s3_ssm_CW_role" {
  name = "S3-SSM-CW-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name        = "S3-SSM-Role"
    Purpose     = "Allow EC2 to access S3 and use SSM agent"
    Environment = var.environment
  }

}

resource "aws_iam_role_policy_attachment" "ssm_core_attach" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "s3_readonly_attach" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "secret_manager-ReadWrite" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_role_policy_attachment" "ssmparameter_read_only" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attachment" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = aws_iam_policy.cloudwatch_agent_policy.arn
  # arn:aws:iam::513410254332:policy/log-group-log-streams
}


# resource "aws_iam_instance_profile" "s3_ssm_profile" {
resource "aws_iam_instance_profile" "s3_ssm_cw_profile" {
  # name = "S3-SSM-Profile"
  name = "S3-SSM-CW-Profile"
  # role = aws_iam_role.s3_ssm_role.name
  role = aws_iam_role.s3_ssm_CW_role.name
}

## using for each to set iam role policy attachment
# locals {
#   policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
#     "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
#   ]
# }

# resource "aws_iam_role_policy_attachment" "s3_ssm_attach" {
#   for_each   = toset(local.policy_arns)
#   role       = aws_iam_role.s3_ssm_role.name
#   policy_arn = each.key
# }



# Iam role for setting up cloudwatch log through cloudwatch agent
# resource "aws_iam_role" "cloudwatch_agent_role" {
#   name = "cloudwatch-agent-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# policy to attach with s3 and ssm role 
# this policy can be attach standalone to cloudwatch role as well
resource "aws_iam_policy" "cloudwatch_agent_policy" {
  name        = "cloudwatch-agent-policy"
  description = "Policy for EC2 instances to send logs to CloudWatch"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "VisualEditor0",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:GetLogEvents",
          "logs:DeleteLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:log-group:*:log-stream:*"
      },
      {
        "Sid" : "VisualEditor1",
        "Effect" : "Allow",
        "Action" : [
          "logs:ListTagsLogGroup",
          "logs:GetLogRecord",
          "logs:DeleteLogGroup",
          "logs:DescribeLogStreams",
          "logs:DescribeMetricFilters",
          "logs:GetLogGroupFields",
          "logs:CreateLogGroup"
        ],
        "Resource" : "arn:aws:logs:*:*:log-group:*"
      },
      {
        "Sid" : "VisualEditor2",
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogDelivery",
          "logs:DescribeLogGroups",
          "logs:ListLogGroupsForQuery",
          "logs:GetLogDelivery",
          "logs:ListLogGroups",
          "logs:DescribeDestinations"
        ],
        "Resource" : "*"
      }
    ]
    }
  )
}

# this attachment is only for cloudwatch agent specific only
# resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attachment" {
#   role       = aws_iam_role.cloudwatch_agent_role.name
#   policy_arn = aws_iam_policy.cloudwatch_agent_policy.arn
# }

# resource "aws_iam_instance_profile" "cloudwatch_agent_profile" {
#   name = "cloudwatch-agent-profile"
#   role = aws_iam_role.cloudwatch_agent_role.name
# }


