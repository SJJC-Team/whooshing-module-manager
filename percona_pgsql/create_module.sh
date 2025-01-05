#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

module=$1

echo -e "${b}------------------- 创建模块 $module -------------------${n}"

if [[ -z "$module" ]]; then echo -e "${r}错误:请指定模块名称${n}"; exit 1; fi

source /home/woo/.env
module_dir="$WHOOSHING_DATA_DIR/$module"

$(dirname "$0")/vault_login.sh

if vault secrets list | grep -q "^$module/"; then echo -e "${r}存储引擎 $module 已经存在，创建失败"; exit 1; fi

echo -e "${b}启动密钥引擎...${n}"
vault secrets enable -path=$module -version=2 kv

if [[ -d "$module_dir" ]]; then echo -e "${r}模块 $module 已存在${n}"; exit 1; fi

echo -e "${b}正在创建模块...${n}"
mkdir $module_dir
chmod -R 770 $module_dir
chown -R root:whooshing $module_dir

echo -e "${b}------------------- 创建模块 $module 完成 -------------------${n}"