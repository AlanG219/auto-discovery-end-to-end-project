output "Sonarqube_ip" {
    value = aws_instance.sonarqube.public_ip
}

output "sonarqube_dns_name" {
    value = aws_elb.sonarqube_lb.dns_name
}

output "sonarqube_zone_id" {
    value = aws_elb.sonarqube_lb.zone_id
}