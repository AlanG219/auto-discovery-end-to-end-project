locals {
  bastion_script = <<-EOF
#!/bin/bash

# Redirect all output to a log file and console for debugging
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

# Function to set up SSH private key
setup_ssh_key() {
    echo "Setting up SSH private key..."
    # Add the provided private key to the SSH configuration
    echo "${var.private_key}" >> /home/ubuntu/.ssh/id_rsa
    # Set the correct permissions for the private key
    sudo chmod 400 /home/ubuntu/.ssh/id_rsa
    # Change ownership of the private key to the ubuntu user
    sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa
}

# Function to install MySQL server
install_mysql() {
    echo "Installing MySQL server..."
    sudo apt update -y
    sudo apt install mysql-server -y
}

# Function to set the hostname
set_hostname() {
    echo "Setting hostname..."
    sudo hostnamectl set-hostname Bastion
}

# Main function to orchestrate script execution
main() {
    setup_ssh_key
    install_mysql
    set_hostname
}

# Execute main function
main
EOF
}