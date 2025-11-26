# https://github.com/chinmayto/terraform-aws-linux-webserver-cloudwatch-sns/blob/main/main.tf
# https://dev.to/chinmay13/getting-started-with-aws-and-terraform-setting-up-cloudwatch-alarms-for-cpu-utilization-on-aws-ec2-instances-with-terraform-14l2
####################################################
# Create an SNS topic with a email subscription
####################################################
resource "aws_sns_topic" "topic" {
  name = "WebServer-CPU_Utilization_alert"
}

resource "aws_sns_topic_subscription" "topic_email_subscription" {
  count     = length(var.email_address)
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.email_address[count.index]
}

# scale up policy
resource "aws_autoscaling_policy" "scale_up" {
  name = "${var.project_name}-asg-scale-up"
  # autoscaling_group_name = aws_autoscaling_group.asg_name.name
  autoscaling_group_name = var.client_asg_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" #increasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale up alarm
# alarm will trigger the ASG policy (scale/down) based on the metric (CPUUtilization), comparison_operator, threshold
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name                = "${var.project_name}-asg-scale-up-alarm"
  alarm_description         = "asg-scale-up-cpu-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "50" # New instance will be created once CPU utilization is higher than 50 %
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"

  dimensions = {
    # "AutoScalingGroupName" = aws_autoscaling_group.asg_name.name
    "AutoScalingGroupName" = var.client_asg_name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_up.arn, aws_sns_topic.topic.arn]
}

# scale down policy
resource "aws_autoscaling_policy" "scale_down" {
  name = "${var.project_name}-asg-scale-down"
  # autoscaling_group_name = aws_autoscaling_group.asg_name.name
  autoscaling_group_name = var.client_asg_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # decreasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale down alarm
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name                = "${var.project_name}-asg-scale-down-alarm"
  alarm_description         = "asg-scale-down-cpu-alarm"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "5" # Instance will scale down when CPU utilization is lower than 5 %
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"

  dimensions = {
    # "AutoScalingGroupName" = aws_autoscaling_group.asg_name.name
    "AutoScalingGroupName" = var.client_asg_name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_down.arn, aws_sns_topic.topic.arn]
}

resource "aws_autoscaling_policy" "server_scale_up" {
  name                   = "${var.project_name}-server-asg-scale-up"
  autoscaling_group_name = var.server_asg_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" #increasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale up alarm
# alarm will trigger the ASG policy (scale/down) based on the metric (CPUUtilization), comparison_operator, threshold
resource "aws_cloudwatch_metric_alarm" "server_scale_up_alarm" {
  alarm_name                = "${var.project_name}-server-asg-scale-up-alarm"
  alarm_description         = "asg-scale-up-cpu-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "50" # New instance will be created once CPU utilization is higher than 50 %
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"

  dimensions = {
    # "AutoScalingGroupName" = aws_autoscaling_group.server_asg_name.name
    "AutoScalingGroupName" = var.server_asg_name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.server_scale_up.arn, aws_sns_topic.topic.arn]
}

# scale down policy
resource "aws_autoscaling_policy" "server_scale_down" {
  name = "${var.project_name}-server-asg-scale-down"
  # autoscaling_group_name = aws_autoscaling_group.server_asg_name.name
  autoscaling_group_name = var.server_asg_name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # decreasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale down alarm
resource "aws_cloudwatch_metric_alarm" "server_scale_down_alarm" {
  alarm_name                = "${var.project_name}-server-asg-scale-down-alarm"
  alarm_description         = "asg-scale-down-cpu-alarm"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = "2"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/EC2"
  period                    = "120"
  statistic                 = "Average"
  threshold                 = "5" # Instance will scale down when CPU utilization is lower than 5 %
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"
  dimensions = {
    # "AutoScalingGroupName" = aws_autoscaling_group.server_asg_name.name
    "AutoScalingGroupName" = var.server_asg_name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.server_scale_down.arn, aws_sns_topic.topic.arn]
}