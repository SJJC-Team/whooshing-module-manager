# module, backup_name

module_dir="$WHOOSHING_DATA_DIR/$module"

if ! vault secrets list | grep -q "^$module/"; then exit 1; fi

if [[ -z "$(vault kv list $module 2>/dev/null)" ]]; then vault secrets disable $module; exit 2; fi

bak_path=$(mktemp -d)

bak_yaml_path=$bak_path/$module.yaml

/home/woo/.medusa/medusa export $module --format="yaml" -o $bak_yaml_path

bak_name=module-bak/$backup_name

if [[ ! -f "$bak_yaml_path" ]]; then exit 3; fi

/home/woo/.medusa/medusa import $bak_name $bak_yaml_path

vault secrets disable $module

rm -rf $bak_path