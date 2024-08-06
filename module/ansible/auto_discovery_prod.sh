#!/bin/bash
set -x

# Define variables
AWS_CLI_PATH='/usr/local/bin/aws'
PROD_INVENTORY_FILE='/etc/ansible/prod-hosts'
PROD_IPS_FILE='/etc/ansible/prod-ips.list'
PROD_ASG_NAME='pet-auto_prod_asg'
SSH_KEY_PATH="/home/ec2-user/.ssh/id_rsa" 
WAIT_TIME=20

# Function to discover AWS instances and save private IPs to file
aws_discovery() {
    echo "Discovering AWS instances..."
    $AWS_CLI_PATH ec2 describe-instances \
        --filters "Name=tag:aws:autoscaling:groupName,Values=$PROD_ASG_NAME" \
        --query 'Reservations[*].Instances[*].NetworkInterfaces[*].PrivateIpAddress' \
        --output text > "$PROD_IPS_FILE"
}

# Function to update Ansible inventory file
update_inventory() {
    echo "Updating Ansible inventory file..."
    echo "[webservers]" > "$PROD_INVENTORY_FILE"
    while IFS= read -r instance; do
        ssh-keyscan -H "$instance" >> ~/.ssh/known_hosts
        echo "$instance ansible_user=ec2-user ansible_ssh_private_key_file=$SSH_KEY_PATH" >> "$PROD_INVENTORY_FILE"
    done < "$PROD_IPS_FILE"
    echo "Inventory updated successfully."
}

# Function to wait for specified time
wait_for_seconds() {
    echo "Waiting for $WAIT_TIME seconds..."
    sleep "$WAIT_TIME"
}

# Function to check and start Docker container if not running
check_docker_container() {
    echo "Checking and starting Docker containers if not running..."
    while IFS= read -r ip; do
        # Check if container is running
        ssh -i "$SSH_KEY_PATH" ec2-user@"$ip" "docker ps --filter 'name=appContainer' --format '{{.Names}}'" | grep -q "appContainer"
        if [[ $? -ne 0 ]]; then
            # Container not running, execute script to start container
            echo "Starting Docker container on $ip..."
            ssh -i "$SSH_KEY_PATH" ec2-user@"$ip" "/home/ec2-user/scripts/script.sh"
        fi
    done < "$PROD_IPS_FILE"
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