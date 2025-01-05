#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

port=$1
module=$2

if [[ -z "$port" || "$port" -lt 1024 || "$port" -gt 65535 ]]; then echo -e "${r}错误:请指定端口，且端口号必须在 1024 到 65535 之间${n}"; exit 1; fi
if [[ -z "$module" ]]; then echo -e "${r}错误:请指定模块名称${n}"; exit 1; fi

export PATH=/usr/lib/postgresql/17/bin:$PATH
source /home/woo/.env

$(dirname "$0")/login_vault.sh

data_dir="$WHOOSHING_DATA_DIR/$module/percona/$port"
sudo -u woo env "PATH=$PATH" pg_ctl stop -D $data_dir
rm -rf $data_dir

$(dirname "$0")/vault_recursive_delete_secret.sh postgres/$port
$(dirname "$0")/vault_recursive_delete_secret.sh postgres/data/$port
echo -e "${g}成功: 已删除端口 $port 的服务器和相关的 Vault 密钥${n}"
