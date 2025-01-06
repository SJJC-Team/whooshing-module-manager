#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

module=$1
port=$2
database=$3

echo -e "${b}------------------- 在模块 $module 的 $port 端口创建数据库 $database -------------------${n}"

if [[ -z "$port" || "$port" -lt 1024 || "$port" -gt 65535 ]]; then echo -e "${r}错误:请指定端口，且端口号必须在 1024 到 65535 之间${n}"; exit 1; fi
if [[ -z "$database" ]]; then echo -e "${r}错误:请指定数据库名称${n}"; exit 1; fi
if [[ -z "$module" ]]; then echo -e "${r}错误:请指定模块名称${n}"; exit 1; fi

export PATH=/usr/lib/postgresql/17/bin:$PATH
source /home/woo/.env

$(dirname "$0")/vault_login.sh

if ! key=$(vault kv get -field=key $module/$port/role/woo 2>/dev/null); then echo -e "${r}错误: 无法获取 Vault 密钥${n}"; exit 1; fi
echo -e "${b}正在创建数据库并设置加密...${n}"
sudo -u woo PGPASSWORD=$key psql -d template1 -p $port -U woo -c "CREATE DATABASE $database;"
sudo -u woo PGPASSWORD=$key psql -d $database -p $port -U woo -c "SELECT pg_tde_add_key_provider_vault_v2('vault-provider','$WHOOSHING_VAULT_ROOT_TOKEN','http://localhost:9412', '$module', NULL);"
sudo -u woo PGPASSWORD=$key psql -d $database -p $port -U woo -c "SELECT pg_tde_set_principal_key('$port/tde/$database', 'vault-provider');"

echo -e "${b}------------------- 在模块 $module 的 $port 端口创建数据库 $database 完成 -------------------${n}"