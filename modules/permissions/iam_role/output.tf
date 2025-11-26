# output "s3_ssm_role_name" {
output "s3_ssm_cw_role_name" {
  description = "IAM role name for S3 and SSM access"
  # value       = aws_iam_role.s3_ssm_role.name
  value = aws_iam_role.s3_ssm_CW_role.name
}
# output "s3_ssm_instance_profile_name" {
output "s3_ssm_cw_instance_profile_name" {
  description = "IAM role name for S3 and SSM access"
  # value       = aws_iam_instance_profile.s3_ssm_profile.name
  value = aws_iam_instance_profile.s3_ssm_cw_profile.name
}

# for cloudwatch specific agent role only
# output "cloudwatch_agent_role" {
#   description = "IAM role name for S3 and SSM access"
#   value       = aws_iam_role.cloudwatch_agent_role.name
# }
# output "cloudwatch_agent_profile_name" {
#   description = "IAM role name for S3 and SSM access"
#   value       = aws_iam_instance_profile.cloudwatch_agent_profile.name
# }


