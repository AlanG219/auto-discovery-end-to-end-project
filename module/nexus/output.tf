output "nexus_ip" {
  value = aws_instance.nexus.public_ip
}
output "nexus_dns_name" {
    value = aws_elb.nexus_lb.dns_name 
}
output "nexus_zone_id" {
    value = aws_elb.nexus_lb.zone_id
}