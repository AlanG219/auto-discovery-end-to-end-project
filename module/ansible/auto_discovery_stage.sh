#!/bin/bash
set -x

# Function to discover AWS instances and save private IPs to file
aws_discovery() {
    echo "Discovering AWS instances..."
    /usr/local/bin/aws ec2 describe-instances \
        --filters "Name=tag:aws:autoscaling:groupName,Values=pet-auto_stage_asg" \
        --query 'Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddress' \
        --output text > "/etc/ansible/stage-ips.list"
}

# Function to update Ansible inventory file
update_inventory() {
    echo "Updating Ansible inventory file..."
    echo "[webservers]" > "/etc/ansible/stage-hosts"
    while IFS= read -r instance; do
        ssh-keyscan -H "$instance" >> ~/.ssh/known_hosts
        echo "$instance ansible_user=ec2-user ansible_ssh_private_key_file=/home/ec2-user/.ssh/id_rsa" >> "/etc/ansible/stage-hosts"
    done < "/etc/ansible/stage-ips.list"
    echo "Inventory updated successfully."
}

# Function to wait for specified time
wait_for_seconds() {
    echo "Waiting for 20 seconds..."
    sleep "20"
}

# Function to check and start Docker container if not running
check_docker_container() {
    echo "Checking and starting Docker containers if not running..."
    while IFS= read -r ip; do
        # Check if container is running
        ssh -i "/home/ec2-user/.ssh/id_rsa" ec2-user@"$ip" "docker ps --filter 'name=appContainer' --format '{{.Names}}'" | grep -q "appContainer"
        if [[ $? -ne 0 ]]; then
            # Container not running, execute script to start container
            echo "Starting Docker container on $ip..."
            ssh -i "/home/ec2-user/.ssh/id_rsa" ec2-user@"$ip" "/home/ec2-user/scripts/script.sh"
        fi
    done < "/etc/ansible/stage-ips.list"
}

# Main function block
main() {
    aws_discovery
    update_inventory
    wait_for_seconds
    check_docker_container
}

# Execute main function
main