#!/bin/bash

# Update system and install Docker and its dependencies, then start Docker service

# Function to update and upgrade the system
update_system() {
    echo "Updating and upgrading the system..."
    sudo yum update -y
    sudo yum upgrade -y
}

# Function to install Docker
install_docker() {
    echo "Installing Docker..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install docker-ce -y
}

# Function to configure Docker to allow insecure registry
configure_docker_registry() {
    echo "Configuring Docker to allow insecure registry..."
    sudo bash -c "cat <<EOT > /etc/docker/daemon.json
{
    \"insecure-registries\" : [\"${nexus-ip}:8085\"]
}
EOT"
}

# Function to start and enable Docker service
start_docker_service() {
    echo "Starting and enabling Docker service..."
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker ec2-user
}

# Function to create a script for managing Docker container
create_docker_script() {
    echo "Creating Docker management script..."
    sudo mkdir -p /home/ec2-user/scripts
    sudo bash -c "cat << EOF > /home/ec2-user/scripts/script.sh
#!/bin/bash
set -x

# Define Variables
IMAGE_NAME=\"${nexus-ip}:8085/petclinicapps\"
CONTAINER_NAME=\"appContainer\"
NEXUS_IP=\"${nexus-ip}:8085\"

# Function to login to Docker registry
authenticate_docker() {
    docker login --username=admin --password=admin123 \$NEXUS_IP
}

# Function to check for the latest image on Docker registry
check_for_updates() {
    local latest_image=\$(docker pull \$IMAGE_NAME | grep \"Status: Image is up to date\" | wc -l)
    if [ \$latest_image -eq 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to stop and remove the current container
# Function to deploy image in a container
update_container() {
    docker stop \$CONTAINER_NAME
    docker rm \$CONTAINER_NAME
    docker run -d --name \$CONTAINER_NAME -p 8080:8080 \$IMAGE_NAME
}

# Main Function
main() {
    authenticate_docker
    if check_for_updates; then
        update_container
        echo \"Container upgraded to the latest image.\"
    else
        echo \"Up to date! No image update required. Exiting...\"
    fi
}
main
EOF"
    sudo chown -R ec2-user:ec2-user /home/ec2-user/scripts
    sudo chmod 755 /home/ec2-user/scripts/script.sh
}

# Function to install New Relic
install_newrelic() {
    echo "Installing New Relic..."
    curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash
    sudo NEW_RELIC_API_KEY="${newrelic-license-key}" NEW_RELIC_ACCOUNT_ID="${newrelic-account-id}" NEW_RELIC_REGION="${newrelic-region}" /usr/local/bin/newrelic install -y
}

# Function to set hostname
set_hostname() {
    echo "Setting hostname..."
    sudo hostnamectl set-hostname prod-instance
}

# Main Function to orchestrate script execution
main() {
    update_system
    install_docker
    configure_docker_registry
    start_docker_service
    create_docker_script
    install_newrelic
    set_hostname
}

# Execute main function
main
