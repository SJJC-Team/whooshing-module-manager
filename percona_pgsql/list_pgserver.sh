#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

module=$1

source /home/woo/.env

if [[ -z "$module" ]]; then echo -e "${r}错误:请指定模块名称${n}"; exit 1; fi
if [[ ! -d "$WHOOSHING_DATA_DIR/$module" ]]; then echo -e "${r}错误: 模块 $module 不存在${n}"; exit 1; fi

directories=()
for dir in "$WHOOSHING_DATA_DIR/$module/percona"/*/; do
    if [ -d "$dir" ]; then directories+=("$dir"); fi
done

if [ ${#directories[@]} -eq 0 ]; then echo -e "${g}当前没有运行任何 PostgreSQL 服务${n}"
else
    for dir in "${directories[@]}"; do echo -e "${g}$(basename "$dir")${n}"; done
fi