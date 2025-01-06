#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

path=$1

if [[ -z "$path" ]]; then echo -e "${r}请指定要删除的路径${n}" ; exit 1; fi

source /home/woo/.env

if ! vault kv get "$path" &>/dev/null; then
	if ! /home/woo/.medusa/medusa delete "$path" -y &>/dev/null; then echo -e "${r}错误: 删除密钥 $path 失败${n}"; exit 1; fi
else
    if ! vault kv get -field=key "$path" &>/dev/null; then echo -e "${g}密钥已删除，无需再删${n}"; exit 1; fi
	if ! vault kv delete "$path" &>/dev/null; then echo -e "${r}错误: 删除密钥 $path 失败${n}"; exit 1; fi
fi

echo -e "${g}成功: 已删除密钥 $path${n}"