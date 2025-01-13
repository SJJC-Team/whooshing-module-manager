vault status > /dev/null 2>&1 || { exit 1; }

vault login "$WHOOSHING_VAULT_ROOT_TOKEN" > /dev/null 2>&1 || { exit 2; }