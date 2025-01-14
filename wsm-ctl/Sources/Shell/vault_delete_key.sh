# path

set -e

if ! vault kv get "$path" &>/dev/null; then
	if ! /home/woo/.medusa/medusa delete "$path" -y &>/dev/null; then exit 2; fi
else
    if ! vault kv get -field=key "$path" &>/dev/null; then exit 1; fi
	if ! vault kv delete "$path" &>/dev/null; then exit 3; fi
fi

echo -e "${g}成功: 已删除密钥 $path${n}"