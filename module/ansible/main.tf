# Ansible server
resource "aws_instance" "ansible-server" {
  ami                         = var.red_hat
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [var.ansible_sg]
  subnet_id                   = var.ansible_subnet
  associate_public_ip_address = true
  key_name                    = var.pub_key
  user_data                   = local.ansible_script
  tags = {
    name = var.ansible_name
  }
}