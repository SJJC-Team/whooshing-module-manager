# path

set -e

if ! key=$(vault kv get -field=key "$path" 2>/dev/null); then exit 1; fi

echo -n "$key"