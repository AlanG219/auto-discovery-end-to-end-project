output "bastion_ip" {
  value = aws_instance.bastion-host.public_ip
} 