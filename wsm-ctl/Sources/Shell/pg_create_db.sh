# module p port_base database key

set -e

port=$(($port_base + $p))

export PATH=/usr/lib/postgresql/17/bin:$PATH

sudo -u woo PGPASSWORD=$key psql -d template1 -p $port -U woo -c "CREATE DATABASE $database;"

# sudo -u woo PGPASSWORD=$key psql -d $database -p $port -U woo -c "SELECT pg_tde_add_global_key_provider_vault_v2('vault-provider','$WHOOSHING_VAULT_ROOT_TOKEN','http://localhost:9412', '$module', NULL);"

sudo -u woo PGPASSWORD=$key psql -d $database -p $port -U woo -c "SELECT pg_tde_set_default_key_using_global_key_provider('$p/tde/$database', 'vault-provider');"
