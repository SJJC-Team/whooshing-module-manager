#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

yaml=$1

echo -e "${b}------------------- 创建服务 -------------------${n}"

function getValue() {
    local yaml_path="$1"
    echo $(yq e .$yaml_path $yaml)
}

function listKeys() {
    local path="$1"
    echo $(yq e ".$path | keys | .[]" "$yaml")
}

function realPort() {
    echo $((20000 + $1))
}

if [ -z "$yaml" ]; then echo -e "${r}请提供 YAML 配置文件${n}"; exit 1; fi
if [ ! -f "$yaml" ]; then echo -e "${r}文件 '$yaml' 未找到或权限不正确${n}"; exit 1; fi

for module in $(listKeys ""); do
    echo -e "${b}创建模块: $module${n}"
    echo ./create_module.sh $module
    
    domain=$(getValue "$module.domain")
    echo -e "${b}基本子域名为: $domain${n}"

    for pgserver in $(listKeys "$module.pgsql"); do
        path=$module.pgsql.$pgserver
        port=$(realPort $(getValue "$path.port"))

        db=$(getValue "$path.database")

        if [ $db != "null" ]; then echo -e "${b}创建 $path, 默认数据库 $db, 监听端口 $port${n}"
        else echo -e "${b}创建 $path, 默认数据库 woo, 监听端口 $port${n}"; db=woo; fi
        
        echo ./create_pg_server.sh $module $port
        echo ./create_database.sh $module $pgserver $db
        
    done

    for name in api inline https; do
        service=$module.$name
        if [ "$(getValue "$service")" != "null" ]; then
        for sub in $(listKeys "$service"); do
            path=$service.$sub
            port=$(realPort $(getValue "$path.port"))
            dbs=($(echo $(getValue "$path.pgdatabases") | yq e '.[]' -))
            
            dbPorts=($(for db in "${dbs[@]}"; do 
                port=$(realPort $(getValue "$module.pgsql.$db.port"))
                if [ "$port" == "null" ]; then echo -e "${r}$path 所依赖的数据库 $db 的监听端口不存在 ${n}" >&2; exit 1; fi
                echo $port
            done))

            domain="null"
            if [ $name != "inline" ]; then
                domain=$(getValue "$path.domain")
                echo -e "${b}创建 $path, 监听端口 $port, 数据库端口 ${dbPorts[@]}, 域名 $domain${n}"
            fi

            if [ $domain == "null" ]; then echo ./create_$name.sh $module $sub $port \"${dbPorts[@]}\"
            else echo ./create_$name.sh $module $sub $port \"${dbPorts[@]}\" $domain; fi
        done
        else echo -e "${g}$service 不存在，跳过...${n}"
    fi
    done
done

echo -e "${b}------------------- 创建服务 完成 -------------------${n}"
