locals {
  sonarqube_script = <<-EOF
#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to update system packages
update_system() {
    echo "Updating system packages..."
    sudo apt update -y
}

# Function to configure system limits
configure_system_limits() {
    echo "Configuring system limits..."
    # Add kernel parameters to sysctl.conf
    sudo bash -c 'cat <<EOF >> /etc/sysctl.conf
vm.max_map_count=262144
fs.file-max=65536
EOF'

    # Add user limits to limits.conf
    sudo bash -c 'cat <<EOF >> /etc/security/limits.conf
sonarqube   -   nofile   65536
sonarqube   -   nproc    4096
EOF'

    # Apply sysctl settings
    sudo sysctl -p
}

# Function to install Java JDK
install_java() {
    echo "Installing Java JDK..."
    sudo apt install openjdk-11-jdk -y
}

# Function to install PostgreSQL
install_postgresql() {
    echo "Installing PostgreSQL 12..."
    # Add PostgreSQL repository
    sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
    # Import PostgreSQL signing key
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    # Update package list
    sudo apt-get update -y
    # Install PostgreSQL 12
    sudo apt-get -y install postgresql-12 postgresql-contrib-12

    echo "Enabling and starting PostgreSQL..."
    # Enable PostgreSQL to start on boot
    sudo systemctl enable postgresql
    # Start PostgreSQL service
    sudo systemctl start postgresql

    echo "Configuring PostgreSQL..."
    # Change default password of postgres user
    sudo chpasswd <<<"postgres:Admin123@"
    # Create sonar user in PostgreSQL
    sudo -u postgres createuser sonar
    # Set password for sonar user
    sudo -u postgres psql -c "ALTER USER sonar WITH ENCRYPTED PASSWORD 'Admin123'"
    # Create SonarQube database
    sudo -u postgres psql -c "CREATE DATABASE sonarqube OWNER sonar"
    # Grant all privileges on the sonarqube database to sonar user
    sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE sonarqube TO sonar"
    # Restart PostgreSQL service to apply changes
    sudo systemctl restart postgresql
}

# Function to install SonarQube
install_sonarqube() {
    echo "Installing SonarQube..."
    # Create directory for SonarQube
    sudo mkdir -p /sonarqube/
    cd /sonarqube/
    # Download SonarQube
    sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-8.6.0.39681.zip
    # Install unzip package
    sudo apt install unzip -y
    # Unzip SonarQube
    sudo unzip sonarqube-8.6.0.39681.zip -d /opt/
    # Move SonarQube to appropriate directory
    sudo mv /opt/sonarqube-8.6.0.39681/ /opt/sonarqube

    echo "Configuring SonarQube..."
    # Create sonar group
    sudo groupadd sonar
    # Create sonar user and add to sonar group
    sudo useradd -c "SonarQube - User" -d /opt/sonarqube/ -g sonar sonar
    # Change ownership of SonarQube directory
    sudo chown sonar:sonar /opt/sonarqube/ -R

    # Add SonarQube configuration to sonar.properties
    sudo bash -c 'cat <<EOF >> /opt/sonarqube/conf/sonar.properties
sonar.jdbc.username=sonar
sonar.jdbc.password=Admin123
sonar.jdbc.url=jdbc:postgresql://localhost/sonarqube
sonar.search.javaOpts=-Xmx512m -Xms512m -XX:+HeapDumpOnOutOfMemoryError
EOF'
}

# Function to configure SonarQube service
configure_sonarqube_service() {
    echo "Configuring SonarQube service..."
    # Create systemd service file for SonarQube
    sudo bash -c 'cat <<EOF > /etc/systemd/system/sonarqube.service
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
ExecReload=/opt/sonarqube/bin/linux-x86-64/sonar.sh restart
User=sonar
Group=sonar
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF'

    echo "Enabling and starting SonarQube service..."
    # Reload systemd manager configuration
    sudo systemctl daemon-reload
    # Enable SonarQube service to start on boot
    sudo systemctl enable sonarqube.service
    # Start SonarQube service
    sudo systemctl start sonarqube.service
}

# Function to install and configure Nginx
install_nginx() {
    echo "Installing and configuring Nginx..."
    # Install Nginx
    sudo apt-get install nginx -y

    # Create Nginx configuration for SonarQube
    sudo bash -c 'cat <<EOF > /etc/nginx/sites-enabled/sonarqube.conf
server {
    listen 80;
    access_log /var/log/nginx/sonar.access.log;
    error_log /var/log/nginx/sonar.error.log;
    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    location / {
        proxy_pass http://127.0.0.1:9000;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
        proxy_redirect off;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
    }
}
EOF'

    # Remove the default Nginx configuration
    sudo rm /etc/nginx/sites-enabled/default
    # Enable Nginx service to start on boot
    sudo systemctl enable nginx.service
    # Restart Nginx service to apply changes
    sudo systemctl restart nginx.service
}

# Function to install New Relic
install_newrelic() {
    echo "Installing New Relic..."
    # Download and install New Relic CLI
    curl -Ls https://download.newrelic.com/install/newrelic-cli/scripts/install.sh | bash
    # Install New Relic with provided API key and account ID
    sudo NEW_RELIC_API_KEY=NRAK-RIPYJAFBUGD6OB6W2RANMN3MYSQ NEW_RELIC_ACCOUNT_ID=4466696 NEW_RELIC_REGION=US /usr/local/bin/newrelic install -y
}

# Function to set hostname
set_hostname() {
    echo "Setting hostname..."
    sudo hostnamectl set-hostname Sonarqube
}

# Main function to orchestrate script execution
main() {
    update_system
    configure_system_limits
    install_java
    install_postgresql
    install_sonarqube
    configure_sonarqube_service
    install_nginx
    install_newrelic
    set_hostname

    echo "Rebooting system..."
    sudo reboot
}

# Execute main function
main
EOF
}