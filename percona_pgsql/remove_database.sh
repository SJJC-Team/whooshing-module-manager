#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

port=$1
name=$2

# 检查端口是否为空或者是否在有效范围内（1024 到 65535 之间）
if [[ -z "$port" || "$port" -lt 1024 || "$port" -gt 65535 ]]; then echo -e "${r}错误:请指定端口，且端口号必须在 1024 到 65535 之间${n}"; exit 1; fi
# 检查名称是否为空
if [[ -z "$name" ]]; then echo -e "${r}错误:请指定数据库名称${n}"; exit 1; fi

export PATH=/usr/lib/postgresql/17/bin:$PATH
source /home/woo/.env

$(dirname "$0")/login_vault.sh

key=$(vault kv get -field=value postgres/$port/root 2>&1)
sudo -u woo PGPASSWORD=$key psql -d template1 -p $port -U woo -c "DROP DATABASE $name;"
$(dirname "$0")/vault_recursive_delete_secret.sh postgres/data/$port/$name
echo -e "${g}成功: 已删除在端口 $port 的数据库 $name 和相关的 Vault 密钥${n}"