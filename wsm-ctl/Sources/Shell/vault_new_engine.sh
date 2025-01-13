# module

if vault secrets list | grep -q "^$module/"; then exit 1; fi

vault secrets enable -path=$module -version=2 kv