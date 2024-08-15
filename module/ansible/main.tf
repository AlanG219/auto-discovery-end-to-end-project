# Ansible server
resource "aws_instance" "ansible-server" {
  ami                         = var.red_hat
  instance_type               = "t2.medium"
  vpc_security_group_ids      = [var.ansible_sg]
  subnet_id                   = var.ansible_subnet
  key_name                    = var.pub_key
  user_data                   = local.ansible_script
  tags = {
    Name = var.ansible_name
  }
}