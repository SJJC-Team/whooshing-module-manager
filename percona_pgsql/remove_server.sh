#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

module=$1
port=$2

echo -e "${b}------------------- 移除模块 $module 的 Percona $port 服务 -------------------${n}"

if [[ -z "$port" || "$port" -lt 1024 || "$port" -gt 65535 ]]; then echo -e "${r}错误:请指定端口，且端口号必须在 1024 到 65535 之间${n}"; exit 1; fi
if [[ -z "$module" ]]; then echo -e "${r}错误:请指定模块名称${n}"; exit 1; fi

export PATH=/usr/lib/postgresql/17/bin:$PATH
source /home/woo/.env

backup_name=${3:-$port-$(date +%Y%m%d%H%M%S)}
percona_dir="$WHOOSHING_DATA_DIR/$module/percona"
data_dir="$percona_dir/$port"

echo -e "${b}备份模块 $module 的密钥...${n}"
$(dirname "$0")/vault_backup_database.sh $port $module $backup_name

sudo -u woo env "PATH=$PATH" pg_ctl stop -D $data_dir

echo -e "${g}正在将端口 $port 的服务器移动到垃圾桶...${n}"
if [[ ! -d $percona_dir/.trash ]]; then mkdir $percona_dir/.trash; fi
if [[ -d "$data_dir" ]]; then mv $data_dir $percona_dir/.trash/$backup_name; fi

echo -e "${b}------------------- 移除模块 $module 的 Percona $port 服务 完成 -------------------${n}"