# Run "source setup_env_vars.sh" command in root directory to ensure environment variables are set before terraform apply
# Alternatively copy and paste the below directly into terminal
export VAULT_ADDR=https://vault.ticktocktv.com
export VAULT_TOKEN=$(cat "./vault/root_token.txt")
