#Run "source setup_env_vars.sh" in root directory to ensure environment variables are set before terraform apply
export VAULT_ADDR='https://vault.ticktocktv.com'
export VAULT_TOKEN=$(cat "./vault/root_token.txt")
