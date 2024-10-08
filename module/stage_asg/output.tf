output "stage-ASG-id" {
  value = aws_autoscaling_group.stage_asg.id
}

output "stage-ASG-name" {
  value = aws_autoscaling_group.stage_asg.name
}

output "stage-LT-id" {
  value = aws_launch_template.stage_lt.image_id
}