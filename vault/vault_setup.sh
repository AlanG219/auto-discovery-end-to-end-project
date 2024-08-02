# Setup script to run once vault is created

# Define the Vault server SSH user and private key for authentication
SSH_USER="ubuntu"
SSH_KEY="./vault-private-key"

# Capture the Vault server IP from Terraform output
VAULT_SERVER_IP=$(terraform output -raw vault_server_public_ip)

# Copy the root token file from the remote server to the local machine
scp -i "$SSH_KEY" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SSH_USER@$VAULT_SERVER_IP:root_token.txt" .

# Change directory to the root level of the Terraform project
cd ..

# Set the Vault address and token as environment variables
export VAULT_ADDR="https://vault.ticktocktv.com"
chmod 600 vault/root_token.txt
export VAULT_TOKEN=$(cat vault/root_token.txt)