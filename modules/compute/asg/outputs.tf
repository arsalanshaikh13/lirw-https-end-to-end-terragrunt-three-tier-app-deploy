output "client_asg_name" {
  value = aws_autoscaling_group.asg_name.name
}
output "server_asg_name" {
  value = aws_autoscaling_group.server_asg_name.name
}

