#!/bin/bash

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

port=$1
module=$2

if [[ -z "$port" || "$port" -lt 1024 || "$port" -gt 65535 ]]; then echo -e "${r}错误:请指定端口，且端口号必须在 1024 到 65535 之间${n}"; exit 1; fi
if [[ -z "$module" ]]; then echo -e "${r}错误:请指定模块名称${n}"; exit 1; fi

backup_name=${3:-$port-$(date +%Y%m%d%H%M%S)}

source /home/woo/.env
module_dir="$WHOOSHING_DATA_DIR/$module"
if [[ ! -d "$module_dir" ]]; then echo -e "${r}错误: 模块 $module 不存在${n}"; exit 1; fi
if ! vault secrets list | grep -q "^$module/"; then echo -e "${r}错误: 存储引擎 $module 不存在，备份失败"; exit 1; fi
bak_path=$(mktemp -d)
bak_yaml_path=$bak_path/$module.yaml
if ! /home/woo/.medusa/medusa export $module/$port --format="yaml" -o $bak_yaml_path 2>/dev/null; then echo -e "${b}模块 $module 的数据库端口 $port 引擎为空，无需备份密钥...${n}"; exit 0; fi
bak_name=server-bak/$backup_name
if [[ ! -f "$bak_yaml_path" ]]; then echo -e "${r}错误: 备份文件 $bak_yaml_path 未成功创建${n}"; exit 1; fi
/home/woo/.medusa/medusa import $module/$bak_name $bak_yaml_path
$(dirname "$0")/vault_delete_secret.sh $module/$port
rm -rf $bak_path
echo -e "${g}成功: 已备份模块 $module 的数据库端口 $port 引擎的密钥到 $module/$bak_name${n}"