locals {
  jenkins_script = <<-EOF
#!/bin/bash

# Function to update system and install necessary packages
install_base_packages() {
    sudo yum update -y
    sudo yum install -y git maven wget yum-utils
}

# Function to install Jenkins
install_jenkins() {
    sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum upgrade -y
    sudo yum install -y java-17-openjdk jenkins
    sudo systemctl daemon-reload
    sudo systemctl enable jenkins
    sudo systemctl start jenkins
}

# Function to install Docker
install_docker() {
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    sudo service docker start
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
    sudo usermod -aG docker jenkins
    sudo chmod 777 /var/run/docker.sock
}

# Function to configure Docker daemon
configure_docker() {
    sudo cat <<EOT > /etc/docker/daemon.json
{
  "insecure-registries" : ["${var.nexus-ip}:8085"]
}
EOT
    sudo systemctl restart docker
}

# Function to install Trivy for container scanning
install_trivy() {
    local RELEASE_VERSION=$(grep -Po '(?<=VERSION_ID=")[0-9]' /etc/os-release)
    sudo cat <<EOT > /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/$RELEASE_VERSION/\$basearch/
gpgcheck=0
enabled=1
EOT
    sudo yum update -y
    sudo yum install -y trivy
}

# Function to install New Relic
install_new_relic() {
    curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash
    sudo NEW_RELIC_API_KEY="${var.nr-key}" NEW_RELIC_ACCOUNT_ID="${var.nr-acc-id}" NEW_RELIC_REGION="${var.nr-region}" /usr/local/bin/newrelic install -y
}

# Function to set the hostname
set_hostname() {
    sudo hostnamectl set-hostname jenkins
}

# Main function to orchestrate script execution
main() {
    install_base_packages
    install_jenkins
    install_docker
    configure_docker
    install_trivy
    install_new_relic
    set_hostname
}

# Execute main function
main

EOF
}