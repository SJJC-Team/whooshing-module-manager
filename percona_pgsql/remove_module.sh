#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

module=$1

echo -e "${b}------------------- 移除模块 $module -------------------${n}"

if [[ -z "$module" ]]; then echo -e "${r}错误:请指定模块名称${n}"; exit 1; fi

source /home/woo/.env
module_dir="$WHOOSHING_DATA_DIR/$module"
backup_name=${2:-$module-$(date +%Y%m%d%H%M%S)}

echo -e "${b}备份模块 $module 的密钥...${n}"
$(dirname "$0")/vault_backup_module.sh $module $backup_name

echo -e "${b}正在将模块 $module 移到垃圾桶...${n}"
if [[ ! -d $WHOOSHING_DATA_DIR/.trash ]]; then mkdir $WHOOSHING_DATA_DIR/.trash; fi
if [[ -d "$module_dir" ]]; then mv $module_dir $WHOOSHING_DATA_DIR/.trash/$backup_name; fi


echo -e "${b}------------------- 移除模块 $module -------------------${n}"