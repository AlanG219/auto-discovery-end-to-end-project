resource "aws_instance" "bastion-host" {
  ami                         = var.ami
  instance_type               = var.instance_type
  key_name                    = var.ssh_key
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.bastion_sg]
  associate_public_ip_address = true
  user_data = local.bastion_script

  tags = {
    Name    = var.name 
  }
}