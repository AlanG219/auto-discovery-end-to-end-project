locals {
  ansible_script = <<-EOF
    #!/bin/bash
    # Redirect all output to a log file and console for debugging
    exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

    # Function to update the instance and install basic utilities
    update_instance() {
        echo "Updating instance and installing basic utilities..."
        sudo yum update -y
        sudo yum install wget -y
        sudo yum install unzip -y
    }

    # Function to install and configure AWS CLI
    install_awscli() {
        echo "Installing and configuring AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        unzip awscliv2.zip
        sudo ./aws/install
        sudo ln -svf /usr/local/bin/aws /usr/bin/aws
        sudo bash -c 'echo "StrictHostKeyChecking No" >> /etc/ssh/ssh_config'

        # Configuring AWS CLI
        sudo su -c "aws configure set aws_access_key_id ${aws_iam_access_key.ansible-user-key.id}" ec2-user
        sudo su -c "aws configure set aws_secret_access_key ${aws_iam_access_key.ansible-user-key.secret}" ec2-user
        sudo su -c "aws configure set default.region eu-west-1" ec2-user
        sudo su -c "aws configure set default.output json" ec2-user

        # Setting environment variables
        export AWS_ACCESS_KEY_ID=${aws_iam_access_key.ansible-user-key.id}
        export AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.ansible-user-key.secret}
    }

    # Function to install Ansible and its dependencies
    install_ansible() {
        echo "Installing Ansible and dependencies..."
        wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
        sudo yum install epel-release-latest-9.noarch.rpm -y
        sudo yum update -y
        sudo yum install python python-devel python-pip ansible -y
    }

    # Function to copy necessary files to the Ansible server
    copy_files_to_ansible_server() {
        echo "Copying files to Ansible server..."
        sudo echo "${file(var.stage-playbook)}" >> /etc/ansible/stage_playbook.yml
        sudo echo "${file(var.prod-playbook)}" >> /etc/ansible/prod_playbook.yml
        sudo echo "${file(var.stage-discovery-script)}" >> /etc/ansible/auto_discovery_stage.sh
        sudo echo "${file(var.prod-discovery-script)}" >> /etc/ansible/auto_discovery_prod.sh
        sudo echo "${var.private_key}" >> /home/ec2-user/.ssh/id_rsa
        sudo bash -c 'echo "NEXUS_IP: \"${var.nexus-ip}:8085\"" > /etc/ansible/ansible_vars_file.yml'


        # Setting permissions for the copied files
        sudo chown -R ec2-user:ec2-user /etc/ansible
        chmod 600 /home/ec2-user/.ssh/id_rsa
        chmod 700 /home/ec2-user/.ssh
        chown ec2-user:ec2-user /home/ec2-user/.ssh/id_rsa
        chown ec2-user:ec2-user /home/ec2-user/.ssh
        sudo chmod 755 /etc/ansible/auto_discovery_stage.sh
        sudo chmod 755 /etc/ansible/auto_discovery_prod.sh
    }

    configure_cron_jobs() {
        echo "Configuring cron jobs for the discovery scripts..."

        # Create a new cron job file in /etc/cron.d
        sudo bash -c 'cat <<EOF > /etc/cron.d/auto_discovery
    * * * * * ec2-user /bin/sh /etc/ansible/auto_discovery_stage.sh >> /home/ec2-user/auto_discovery_stage.log 2>&1
    * * * * * ec2-user /bin/sh /etc/ansible/auto_discovery_prod.sh >> /home/ec2-user/auto_discovery_prod.log 2>&1
    EOF'

    # Ensure the cron job file has the correct permissions
    sudo chmod 644 /etc/cron.d/auto_discovery

    echo "Cron jobs configured successfully."
}



    # Function to install and configure New Relic
    install_newrelic() {
        echo "Installing New Relic..."
        curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash
        sudo NEW_RELIC_API_KEY="${var.newrelic-license-key}" NEW_RELIC_ACCOUNT_ID="${var.newrelic-acct-id}" NEW_RELIC_REGION=US /usr/local/bin/newrelic install -y
    }

    # Function to set the hostname
    set_hostname() {
        echo "Setting hostname..."
        sudo hostnamectl set-hostname ansible
    }

    # Main function to orchestrate script execution
    main() {
        update_instance
        install_awscli
        install_ansible
        copy_files_to_ansible_server
        configure_cron_jobs
        install_newrelic
        set_hostname
    }

    # Execute main function
    main
    EOF
}