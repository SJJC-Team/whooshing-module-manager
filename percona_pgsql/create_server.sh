#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

port=$1

echo -e "${b}------------------- Percona PostgreSQL 创建服务 $port -------------------${n}"

# 检查端口是否为空或者是否在有效范围内（1024 到 65535 之间）
if [[ -z "$port" || "$port" -lt 1024 || "$port" -gt 65535 ]]; then echo -e "${r}错误:请指定端口，且端口号必须在 1024 到 65535 之间${n}"; exit 1; fi
# 检查端口是否被占用
if lsof -i:"$port" > /dev/null 2>&1; then echo -e "${r}错误:端口 $port 已被占用${n}"; exit 1; fi

mkdir -p /data/percona
chown postgres:postgres /data
chown -R postgres:postgres /data/percona
chmod -R 700 /data

export PATH=/usr/lib/postgresql/17/bin:$PATH
export VAULT_ADDR='unix:///opt/vault/vault.sock'
source /root/.env

# 检查 Vault 是否已解封
echo -e "${b}检查 Vault 是否已解封...${n}"
if ! vault status > /dev/null 2>&1; then
    echo -e "${r}错误: Vault 未解封，请先解封 Vault${n}"
    exit 1
fi

echo -e "${b}登录 Vault...${n}"
vault login "$VAULT_ROOT_TOKEN" > /dev/null 2>&1 || { echo "${r}发生错误: vault 登陆失败！${n}" >&2; exit 1; }
if ! vault kv get postgres/$port/root > /dev/null 2>&1; then 
    echo -e "${b}生成新的 Vault 密钥...${n}"
    if ! vault secrets list | grep -q '^postgres/'; then vault secrets enable -path=postgres kv; fi
    vault kv put postgres/$port/root value=$(openssl rand -hex 64)
fi
key=$(vault kv get -field=value postgres/$port/root 2>&1)

# 创建数据目录
echo -e "${b}创建数据目录...${n}"
data_dir="/data/percona/$port"
conf_file="$data_dir/postgresql.conf"
sudo -u postgres mkdir -p "$data_dir"
sudo -u postgres chown -R postgres:postgres "$data_dir"
sudo -u postgres chmod 700 "$data_dir"

# 初始化数据库
echo -e "${b}初始化数据库...${n}"
sudo -u postgres env "PATH=$PATH" pg_ctl init -D "$data_dir"
sudo -u postgres echo "listen_addresses = 'localhost'" >> "$conf_file"
sudo -u postgres echo "shared_preload_libraries=pg_tde" >> "$conf_file"
sudo -u postgres echo "port = $port" >> "$conf_file"
sudo -u postgres env "PATH=$PATH" pg_ctl start -D "$data_dir" -l $data_dir/log

# 创建扩展 - pg_tde
echo -e "${b}创建扩展 - pg_tde...${n}"
sudo -u postgres psql -d template1 -p $port -U postgres -c "DROP DATABASE postgres;"
sudo -u postgres psql -d template1 -p $port -U postgres -c "CREATE EXTENSION pg_tde;"
sudo -u postgres psql -d template1 -p $port -U postgres -c "SELECT pg_tde_add_key_provider_vault_v2('vault-provider','$VAULT_ROOT_TOKEN','http://localhost:9412', 'postgres', NULL);"
sudo -u postgres psql -d template1 -p $port -U postgres -c "SELECT pg_tde_set_principal_key('$port/template1/tde', 'vault-provider');"

# 设置密码
echo -e "${b}设置密码...${n}"
sudo -u postgres psql -d template1 -p $port -U postgres -c "ALTER USER postgres WITH PASSWORD '$key';"

# 修改配置文件
echo -e "${b}修改配置文件...${n}"
sudo -u postgres rm -f $data_dir/pg_hba.conf
sudo -u postgres cp "$(dirname "$0")/pg_hba.conf" $data_dir/pg_hba.conf

# 重启服务
echo -e "${b}重启服务...${n}"
sudo systemctl restart postgresql.service
sudo -u postgres env "PATH=$PATH" pg_ctl restart -D "$data_dir" -l $data_dir/log

echo -e "${b}------------------- Percona PostgreSQL 创建服务 $port 完成 -------------------${n}"
