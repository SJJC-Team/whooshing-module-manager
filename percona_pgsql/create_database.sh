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
export VAULT_ADDR='unix:///opt/vault/vault.sock'
source /root/.env
vault login "$VAULT_ROOT_TOKEN" > /dev/null 2>&1 || { echo "${r}发生错误: vault 登陆失败！${n}" >&2; exit 1; }
key=$(vault kv get -field=value postgres/$port/root 2>&1)
sudo -u postgres PGPASSWORD=$key psql -d template1 -p $port -U postgres -c "CREATE DATABASE $name;"
sudo -u postgres PGPASSWORD=$key psql -d $name -p $port -U postgres -c "SELECT pg_tde_add_key_provider_vault_v2('vault-provider','$VAULT_ROOT_TOKEN','http://localhost:9412', 'postgres', NULL);"
sudo -u postgres PGPASSWORD=$key psql -d $name -p $port -U postgres -c "SELECT pg_tde_set_principal_key('$port/$name/tde', 'vault-provider');"