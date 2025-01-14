set -e

vault status || { exit 1; }

vault login "$WHOOSHING_VAULT_ROOT_TOKEN" || { exit 2; }