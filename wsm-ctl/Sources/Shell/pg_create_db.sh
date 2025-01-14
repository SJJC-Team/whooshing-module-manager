# module port database key

set -e

export PATH=/usr/lib/postgresql/17/bin:$PATH

sudo -u woo PGPASSWORD=$key psql -d template1 -p $port -U woo -c "CREATE DATABASE $database;"

sudo -u woo PGPASSWORD=$key psql -d $database -p $port -U woo -c "SELECT pg_tde_add_key_provider_vault_v2('vault-provider','$WHOOSHING_VAULT_ROOT_TOKEN','http://localhost:9412', '$module', NULL);"

sudo -u woo PGPASSWORD=$key psql -d $database -p $port -U woo -c "SELECT pg_tde_set_principal_key('$port/tde/$database', 'vault-provider');"
