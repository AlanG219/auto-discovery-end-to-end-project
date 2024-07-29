#!/bin/bash

# Update package repositories
sudo apt update

# Download and install Consul
sudo wget https://releases.hashicorp.com/consul/1.7.3/consul_1.7.3_linux_amd64.zip
sudo apt install unzip -y
sudo unzip consul_1.7.3_linux_amd64.zip
sudo mv consul /usr/bin/

# Create a Consul systemd service
sudo cat <<EOT>> /etc/systemd/system/consul.service
[Unit]
Description=Consul
Documentation=https://www.consul.io/

[Service]
ExecStart=/usr/bin/consul agent -server -ui -data-dir=/temp/consul -bootstrap-expect=1 -node=vault -bind=$(hostname -i) -config-dir=/etc/consul.d/
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

# Create Consul configuration directory and UI settings
sudo mkdir /etc/consul.d 
sudo cat <<EOT>> /etc/consul.d/ui.json
{
    "addresses":{
    "http": "0.0.0.0"
    }
}
EOT

# Reload systemd, start, and enable Consul service
sudo systemctl daemon-reload
sudo systemctl start consul
sudo systemctl enable consul

# Download and install Vault
sudo apt update
sudo wget https://releases.hashicorp.com/vault/1.5.0/vault_1.5.0_linux_amd64.zip
sudo unzip vault_1.5.0_linux_amd64.zip
sudo mv vault /usr/bin/

# Create Vault configuration file
sudo mkdir /etc/vault/
sudo cat <<EOT>> /etc/vault/config.hcl
storage "consul" {
    address = "127.0.0.1:8500"
    path    = "vault/"
}

listener "tcp" {
    address        = "0.0.0.0:8200"
    tls_disable    = 1
}

seal "awskms" {
    region     = "eu-west-1"
    kms_key_id = "${kms_key}"
}
ui = true
EOT

# Create Vault systemd service
sudo cat <<EOT>> /etc/systemd/system/vault.service
[Unit]
Description=Vault
Documentation=https://www.vault.io/

[Service]
ExecStart=/usr/bin/vault server -config=/etc/vault/config.hcl
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOT

# Reload systemd, start, and enable Vault service
sudo systemctl daemon-reload
export VAULT_ADDR="http://localhost:8200"
cat <<EOT > /etc/profile.d/vault.sh
export VAULT_ADDR="http://localhost:8200"
export VAULT_SKIP_VERIFY=true
EOT
vault -autocomplete-install
complete -C /usr/bin/vault vault

# Notify once provisioned
echo "Vault server provisioned successfully."

# Start Vault service
sudo systemctl start vault
sudo systemctl enable vault

# Set hostname to Vault
sudo hostnamectl set-hostname Vault

# Add keypair to server to retrieve our token
echo "${keypair}" >> /home/ubuntu/.ssh/id_rsa
chmod 400 /home/ubuntu/.ssh/id_rsa
sudo chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

# Code to setup and configure vault
sudo tee /home/ubuntu/vault_setup.sh > /dev/null <<'EOT'
#!/bin/bash

# Sleep for 20 seconds to allow the Vault server to fully start
sleep 20

# Define the Vault server SSH user and private key for authentication
SSH_USER="ubuntu"
SSH_KEY="./vault-private-key"

# Function to generate a random password
generate_random_password() {
    openssl rand -base64 16
}

# Function to run Vault commands on the remote server
run_vault_commands() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$VAULT_SERVER_IP" << EOF
# Initialize Vault
init_output=\$(vault operator init -format=json)

# Capture the root token
root_token=\$(echo \$init_output | jq -r '.root_token')

# Save the root token to a file (optional, for reference)
echo \$root_token > root_token.txt

# Log in to Vault using the root token
vault login \$root_token

# Enable KV secrets engine at the specified path
vault secrets enable -path=secret/ kv

# Generate a random password
random_password=\$(openssl rand -base64 16)

# Store username and random password in the KV secrets engine
vault kv put secret/database username=admin password=\$random_password

echo "Vault setup completed successfully with a random password."
echo "Generated random password: \$random_password"
EOF

    # Securely copy the root token file from the remote server to the local machine
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$VAULT_SERVER_IP:root_token.txt" .
}

# Capture the Vault server IP from Terraform output
VAULT_SERVER_IP=$(terraform output -raw vault_server_public_ip)

# Run the function to SSH into the Vault server and execute the Vault commands
run_vault_commands
EOT

# Make the script executable and set appropriate ownership
sudo chmod +x /home/ubuntu/vault_setup.sh
sudo chown ubuntu:ubuntu /home/ubuntu/vault_setup.sh