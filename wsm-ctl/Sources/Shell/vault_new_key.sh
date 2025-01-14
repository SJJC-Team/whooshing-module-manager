# path

set -e

if ! vault kv get "$path"; then vault kv put "$path" key=$(openssl rand -hex 32)
else exit 1; fi