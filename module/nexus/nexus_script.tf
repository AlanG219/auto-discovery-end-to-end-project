locals {
  nexus_user_data = <<-EOF
#!/bin/bash

# Function to update the system and install necessary packages
install_dependencies() {
    echo "Updating system and installing necessary packages..."
    sudo yum update -y
    sudo yum install wget -y
    sudo yum install java-1.8.0-openjdk.x86_64 -y
}

# Function to download and extract Nexus
install_nexus() {
    echo "Downloading and extracting Nexus..."
    sudo mkdir /app && cd /app
    sudo wget http://download.sonatype.com/nexus/3/nexus-3.23.0-03-unix.tar.gz
    sudo tar -xvf nexus-3.23.0-03-unix.tar.gz
    sudo mv nexus-3.23.0-03 nexus
}

# Function to set up Nexus user and permissions
setup_nexus_user() {
    echo "Setting up Nexus user and permissions..."
    sudo adduser nexus
    sudo chown -R nexus:nexus /app/nexus
    sudo chown -R nexus:nexus /app/sonatype-work
    sudo cat <<EOT> /app/nexus/bin/nexus.rc
run_as_user="nexus"
EOT
}

# Function to configure Nexus memory settings
configure_nexus_memory() {
    echo "Configuring Nexus memory settings..."
    sed -i '2s/-Xms2703m/-Xms512m/' /app/nexus/bin/nexus.vmoptions
    sed -i '3s/-Xmx2703m/-Xmx512m/' /app/nexus/bin/nexus.vmoptions
    sed -i '4s/-XX:MaxDirectMemorySize=2703m/-XX:MaxDirectMemorySize=512m/' /app/nexus/bin/nexus.vmoptions
}

# Function to create systemd service for Nexus
create_nexus_service() {
    echo "Creating systemd service for Nexus..."
    sudo cat <<EOT> /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target
[Service]
Type=forking
LimitNOFILE=65536
User=nexus
Group=nexus
ExecStart=/app/nexus/bin/nexus start
ExecStop=/app/nexus/bin/nexus stop
Restart=on-abort
[Install]
WantedBy=multi-user.target
EOT
    sudo ln -s /app/nexus/bin/nexus /etc/init.d/nexus
    sudo chkconfig --add nexus
    sudo chkconfig --levels 345 nexus on
    sudo service nexus start
}

# Function to install New Relic
install_new_relic() {
    echo "Installing New Relic..."
    curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash
    sudo NEW_RELIC_API_KEY=${var.newrelic_api_key} NEW_RELIC_ACCOUNT_ID=${var.newrelic_account_id} NEW_RELIC_REGION=${var.newrelic_region} /usr/local/bin/newrelic install -y
}

# Function to set the hostname
set_hostname() {
    echo "Setting hostname to Nexus..."
    sudo hostnamectl set-hostname Nexus
}

# Main function to orchestrate the script execution
main() {
    install_dependencies
    install_nexus
    setup_nexus_user
    configure_nexus_memory
    create_nexus_service
    install_new_relic
    set_hostname
}

# Execute main function
main
EOF
}
