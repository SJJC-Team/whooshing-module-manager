#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

module=$1
port=$2

# 检查 module 是否为空

echo -e "${b}------------------- Percona PostgreSQL 在模块 $module 创建服务 $port -------------------${n}"

if [[ -z "$port" || "$port" -lt 1024 || "$port" -gt 65535 ]]; then echo -e "${r}错误:请指定端口，且端口号必须在 1024 到 65535 之间${n}"; exit 1; fi
if lsof -i:"$port" > /dev/null 2>&1; then echo -e "${r}错误:端口 $port 已被占用${n}"; exit 1; fi
if [[ -z "$module" ]]; then echo -e "${r}错误:请指定模块名称${n}"; exit 1; fi

export PATH=/usr/lib/postgresql/17/bin:$PATH
source /home/woo/.env

module_dir="$WHOOSHING_DATA_DIR/$module"
percona_dir="$module_dir/percona"
data_dir="$percona_dir/$port"

if [[ ! -d "$module_dir" ]]; then echo -e "${r}错误: 模块 $module 不存在${n}"; exit 1; fi
if [[ -d "$data_dir" ]]; then echo -e "${r}错误: 该服务已经存在${n}"; exit 1; fi

# 创建数据目录
echo -e "${b}创建数据目录...${n}"
mkdir -p "$data_dir"
chown -R woo:whooshing "$percona_dir"
chmod -R 700 "$percona_dir"

$(dirname "$0")/vault_login.sh

if ! vault kv get $module/$port/role/woo > /dev/null 2>&1; then 
    echo -e "${b}生成新的 Vault 密钥...${n}"
    vault kv put $module/$port/role/woo key=$(openssl rand -hex 64)
fi

if ! key=$(vault kv get -field=key $module/$port/role/woo 2>/dev/null); then echo -e "${r}错误: 无法获取 Vault 密钥${n}"; exit 1; fi

conf_file="$data_dir/postgresql.conf"

# 初始化数据库
echo -e "${b}初始化数据库...${n}"
sudo -u woo env "PATH=$PATH" pg_ctl init -D "$data_dir"
sudo -u woo echo "listen_addresses = 'localhost'" >> "$conf_file"
sudo -u woo echo "shared_preload_libraries=pg_tde" >> "$conf_file"
sudo -u woo echo "port = $port" >> "$conf_file"
sudo -u woo env "PATH=$PATH" pg_ctl start -D "$data_dir" -l $data_dir/log

# 创建扩展 - pg_tde
echo -e "${b}创建扩展 - pg_tde...${n}"
sudo -u woo psql -d template1 -p $port -U woo -c "DROP DATABASE postgres;"
sudo -u woo psql -d template1 -p $port -U woo -c "CREATE EXTENSION pg_tde;"
sudo -u woo psql -d template1 -p $port -U woo -c "SELECT pg_tde_add_key_provider_vault_v2('vault-provider','$WHOOSHING_VAULT_ROOT_TOKEN','http://localhost:9412', '$module', NULL);"
sudo -u woo psql -d template1 -p $port -U woo -c "SELECT pg_tde_set_principal_key('$port/tde/template1', 'vault-provider');"

# 设置密码
echo -e "${b}设置密码...${n}"
sudo -u woo psql -d template1 -p $port -U woo -c "ALTER USER woo WITH PASSWORD '$key';"

# 修改配置文件
echo -e "${b}修改配置文件...${n}"
sudo -u woo rm -f $data_dir/pg_hba.conf
sudo -u woo cp "$(dirname "$0")/pg_hba.conf" $data_dir/pg_hba.conf

chown -R woo:whooshing "$data_dir"
chmod -R 700 "$data_dir"

# 重启服务
echo -e "${b}重启服务...${n}"
sudo systemctl restart postgresql.service
sudo -u woo env "PATH=$PATH" pg_ctl restart -D "$data_dir" -l $data_dir/log

echo -e "${b}------------------- Percona PostgreSQL 在模块 $module 创建服务 $port 完成 -------------------${n}"
