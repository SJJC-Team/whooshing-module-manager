# module port backup_name

set -e

module_dir="$WHOOSHING_DATA_DIR/$module"

if ! vault secrets list | grep -q "^$module/"; then exit 1; fi

bak_path=$(mktemp -d)

bak_yaml_path="$bak_path/$module.yaml"

if ! /home/woo/.medusa/medusa export "$module/$port" --format="yaml" -o "$bak_yaml_path" 2>/dev/null; then exit 2; fi

bak_name="server-bak/$backup_name"

if [[ ! -f "$bak_yaml_path" ]]; then exit 3; fi

/home/woo/.medusa/medusa import "$module/$bak_name" "$bak_yaml_path"

rm -rf "$bak_path"