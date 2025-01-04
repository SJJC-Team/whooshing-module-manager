#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

vault_token=$1

echo -e "${b}------------------- Percona PostgreSQL 初始化 -------------------${n}"

# 检查 Vault token 是否为空
if [[ -z "$vault_token" ]]; then
    echo -e "${r}错误:请提供 Vault Token${n}"
    exit 1
fi

export VAULT_ADDR='unix:///opt/vault/vault.sock'

# 检查 Vault 是否已解封
echo -e "${b}检查 Vault 是否已解封...${n}"
if ! vault status > /dev/null 2>&1; then
    echo -e "${r}错误: Vault 未解封，请先解封 Vault${n}"
    exit 1
fi

echo -e "${b}登录 Vault...${n}"
vault login $vault_token
if ! vault kv get postgres/postgres > /dev/null 2>&1; then 
    echo -e "${b}生成新的 Vault 密钥...${n}"
    vault kv put postgres/postgres value=$(openssl rand -hex 64)
fi
key=$(vault kv get -field=value postgres/postgres 2>&1)

echo -e "${g}创建配置目录...${n}"
mkdir -p /root/configs
cd /root/configs

echo -e "${g}下载 Percona Release 包...${n}"
wget https://repo.percona.com/apt/percona-release_latest.$(lsb_release -sc)_all.deb

echo -e "${g}安装 Percona Release 包...${n}"
sudo dpkg -i percona-release_latest.$(lsb_release -sc)_all.deb

echo -e "${g}更新包列表...${n}"
sudo apt update

echo -e "${g}设置 Percona PostgreSQL 仓库...${n}"
sudo percona-release setup ppg-17

echo -e "${g}安装 Percona PostgreSQL 服务器...${n}"
expect << EOF
spawn sudo apt install percona-ppg-server-17
expect "Do you want to continue?" { send "Y\r" }
expect eof
EOF

echo -e "${g}更新环境变量...${n}"
if ! grep -q '/usr/lib/postgresql/17/bin' /etc/profile; then
    echo 'export PATH=$PATH:/usr/lib/postgresql/17/bin' >> /etc/profile
    source /etc/profile
fi

if [ ! -f /var/lib/postgresql/.bashrc ]; then touch /var/lib/postgresql/.bashrc; fi
if ! grep -q '/usr/lib/postgresql/17/bin' /var/lib/postgresql/.bashrc; then
    echo 'export PATH=$PATH:/usr/lib/postgresql/17/bin' >> /var/lib/postgresql/.bashrc
fi

echo "postgres:$key" | sudo chpasswd

echo -e "${b}------------------- Percona PostgreSQL 初始化 完成 -------------------${n}"