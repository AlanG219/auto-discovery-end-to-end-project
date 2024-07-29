output "vault_server_ip" {
  value = aws_instance.vault_server.public_ip
}