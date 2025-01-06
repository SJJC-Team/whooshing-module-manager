#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

source /home/woo/.env

directories=()
for dir in "$WHOOSHING_DATA_DIR"/*/; do
    if [ -d "$dir" ]; then directories+=("$dir"); fi
done

if [ ${#directories[@]} -eq 0 ]; then echo -e "${g}当前没有任何服务模块${n}"
else
    for dir in "${directories[@]}"; do echo -e "${g}$(basename "$dir")${n}"; done
fi