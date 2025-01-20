set -e

set +e
vault status 2>&1
status=$?
set -e

if [ $status == 2 ]; then 
    exit 3
elif [ $status == 1 ]; then 
    exit 1
fi

vault login "$WHOOSHING_VAULT_ROOT_TOKEN" || { exit 2; }