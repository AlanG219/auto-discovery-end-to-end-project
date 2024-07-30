#!/bin/bash

# Update package repositories and install necessary packages
sudo apt-get update -y
sudo apt-get install -y unzip wget jq

# Download and install Consul
wget https://releases.hashicorp.com/consul/"${CONSUL_VERSION}"/consul_"${CONSUL_VERSION}"_linux_amd64.zip
unzip consul_"${CONSUL_VERSION}"_linux_amd64.zip
sudo mv consul /usr/bin/

# Create a Consul systemd service
cat <<EOT | sudo tee /etc/systemd/system/consul.service
[Unit]
Description=Consul
Documentation=https://www.consul.io/

[Service]
ExecStart=/usr/bin/consul agent -server -ui -data-dir=/tmp/consul -bootstrap-expect=1 -node=vault -bind=${CONSUL_BIND_IP} -config-dir=/etc/consul.d/
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

# Create Consul configuration directory and UI settings
sudo mkdir -p /etc/consul.d
cat <<EOT | sudo tee /etc/consul.d/ui.json
{
    "addresses": {
        "http": "0.0.0.0"
    }
}
EOT

# Reload systemd, start, and enable Consul service
sudo systemctl daemon-reload
sudo systemctl start consul
sudo systemctl enable consul

# Download and install Vault
wget https://releases.hashicorp.com/vault/"${VAULT_VERSION}"/vault_"${VAULT_VERSION}"_linux_amd64.zip
unzip vault_"${VAULT_VERSION}"_linux_amd64.zip
sudo mv vault /usr/bin/

# Create Vault configuration file
sudo mkdir -p /etc/vault/
cat <<EOT | sudo tee /etc/vault/config.hcl
storage "consul" {
    address = "127.0.0.1:8500"
    path    = "vault/"
}

listener "tcp" {
    address     = "0.0.0.0:8200"
    tls_disable = 1
}

seal "awskms" {
    region     = "eu-west-1"
    kms_key_id = "${kms_key}"
}

ui = true
EOT

# Create Vault systemd service
cat <<EOT | sudo tee /etc/systemd/system/vault.service
[Unit]
Description=Vault
Documentation=https://www.vaultproject.io/

[Service]
ExecStart=/usr/bin/vault server -config=/etc/vault/config.hcl
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

# Reload systemd, start, and enable Vault service
sudo systemctl daemon-reload
sudo systemctl start vault
sudo systemctl enable vault

# Sleep for a while to allow Vault to fully start
sleep 20

# Set environment variables for Vault
export VAULT_ADDR="http://localhost:8200"
export VAULT_SKIP_VERIFY=true

# Enable Vault autocomplete
vault -autocomplete-install
complete -C /usr/bin/vault vault

# Initialize Vault and capture the output in JSON format
init_output=$(vault operator init -format=json)

# Extract the root token from the initialization output
root_token=$(echo $init_output | jq -r '.root_token')

# Save the root token to a file on the remote server (optional)
echo $root_token > /home/ubuntu/root_token.txt

# Log in to Vault using the root token
vault login $root_token

# Enable the KV secrets engine at the specified path
vault secrets enable -path=secret/ kv

# Generate a random password using OpenSSL
random_password=$(openssl rand -base64 16)

# Store the username and random password in the KV secrets engine
vault kv put secret/database username=admin password=$random_password

# Print confirmation messages
echo "Vault setup completed successfully with a random password."
echo "Generated random password: $random_password"

# Set hostname to Vault
sudo hostnamectl set-hostname Vault

# Copy keypair
echo "${keypair}" | sudo tee /home/ubuntu/.ssh/id_rsa > /dev/null
sudo chmod 400 /home/ubuntu/.ssh/id_rsa
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

# Notify once provisioned
echo "Vault server provisioned successfully."
