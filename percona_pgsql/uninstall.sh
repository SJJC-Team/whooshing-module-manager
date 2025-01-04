#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

echo -e "${b}------------------- Percona PostgreSQL 卸载 -------------------${n}"

echo -e "${b}终止 PostgreSQL 服务...${n}"
if systemctl list-units --full -all | grep -Fq 'postgresql.service'; then
    echo -e "${b}Stopping PostgreSQL service...${n}"
    sudo systemctl stop postgresql.service
    echo -e "${g}服务已终止${n}"
else
    echo -e "${g}服务未运行${n}"
fi

echo -e "${b}删除 Percona PostgreSQL...${n}"
expect << EOF
spawn sudo apt remove percona-postgresql-17* percona-patroni percona-pgbackrest  percona-pgbadger percona-pgbouncer
expect "Do you want to continue?" { send "Y\r" }
expect eof
EOF
echo -e "${g}删除成功${n}"

echo -e "${b}删除 PostgreSQL...${n}"
expect << EOF
spawn sudo apt-get --purge remove postgresql postgresql-*
expect "Do you want to continue?" { send "Y\r" }
expect eof
EOF
echo -e "${g}删除成功${n}"

echo -e "${b}清除数据目录...${n}"
rm -rf /data/percona
rm -rf /etc/postgresql
echo -e "${b}完成${n}"

echo -e "${b}------------------- Percona PostgreSQL 卸载 完成 -------------------${n}"