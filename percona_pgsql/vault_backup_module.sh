#!/bin/bash

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

module=$1

if [[ -z "$module" ]]; then echo -e "${r}错误:请指定模块名称${n}"; exit 1; fi

backup_name=${2:-$module-$(date +%Y%m%d%H%M%S)}

source /home/woo/.env
module_dir="$WHOOSHING_DATA_DIR/$module"
if [[ ! -d "$module_dir" ]]; then echo -e "${r}错误: 模块 $module 不存在${n}"; exit 1; fi
if ! vault secrets list | grep -q "^$module/"; then echo -e "${r}错误: 存储引擎 $module 不存在，备份失败"; exit 1; fi
if [[ -z "$(vault kv list $module 2>/dev/null)" ]]; then echo -e "${b}存储引擎 $module 为空，无需备份密钥, 禁用 $module 引擎...${n}"; vault secrets disable $module; exit 0; fi
bak_path=$(mktemp -d)
bak_yaml_path=$bak_path/$module.yaml
/home/woo/.medusa/medusa export $module --format="yaml" -o $bak_yaml_path
bak_name=module-bak/$backup_name
if [[ ! -f "$bak_yaml_path" ]]; then echo -e "${r}错误: 备份文件 $bak_yaml_path 未成功创建${n}"; exit 1; fi
/home/woo/.medusa/medusa import $bak_name $bak_yaml_path
vault secrets disable $module
rm -rf $bak_path
echo -e "${g}成功: 已备份引擎 $module 的密钥到 $bak_name${n}"