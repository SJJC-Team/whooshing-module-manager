#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

module=$1
name=$2
port=$3
dbPorts=$4
domain=$5

echo -e "${b}------------------- 创建 api 模块 $module.$name, 端口:$port -------------------${n}"

if [[ -z "$module" || -z "$name" || -z "$port" || -z "$dbPorts" ]]; then echo -e "${r}输入不符合要求${n}"; echo "用法: $0 <模块名> <api 服务名称> <端口号> <数据库端口号(多个)> <域名(可选)>"; exit 1; fi
if [[ -z "$port" || "$port" -lt 1024 || "$port" -gt 65535 ]]; then echo -e "${r}Z请指定端口, 且端口号必须在 1024 到 65535 之间${n}"; exit 1; fi
if ! [[ "$dbPorts" =~ ^([0-9]{4,5}( [0-9]{4,5})*)$ ]]; then echo -e "${r}数据库端口号必须是一个以空格分割的端口数组${n}"; exit 1; fi

IFS=' ' read -r -a dbPortsArr <<< "$dbPorts"

for dbPort in "${dbPortsArr[@]}"; do
    
done

echo -e "${b}------------------- 创建 api 模块 $module.$name, 端口:$port 完成 -------------------${n}"