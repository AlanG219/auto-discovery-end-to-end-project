output "jenkins_ip" {
  value = aws_instance.jenkins.private_ip
}

output "jenkins_lb_zoneid" {
  value = aws_lb.jenkins_lb.zone_id
}

output "jenkins_lb_arn" {
  value = aws_lb.jenkins_lb.arn
}

output "jenkins_lb_dns" {
  value = aws_lb.jenkins_lb.dns_name
}

output "tg_jenkins_arn" {
  value = aws_lb_target_group.jenkins_lb_tg.arn
}