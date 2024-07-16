output "bastion-ip" {
  value = module.bastion.bastion_ip
}

output "jenkins-ip" {
  value = module.jenkins.jenkins_ip
}

output "rds-endpoint" {
  value = module.rds.rds_endpoint
}

output "sonarqube-ip" {
  value = module.sonarqube.Sonarqube_ip
}

output "nexus-ip" {
  value = module.nexus.nexus_ip
}

output "ansible-ip" {
  value = module.ansible.ansible_ip
}

