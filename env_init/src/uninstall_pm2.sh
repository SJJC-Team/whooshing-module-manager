#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

echo -e "${b}------------------- Pm2 卸载 -------------------${n}"

if command -v nvm > /dev/null 2>&1; then
    . nvm use 23
    echo -e "${b}删除 pm2 工具${n}"
    npm uninstall pm2 -g
else
    echo -e "${r}nvm 未安装，跳过 pm2 卸载${n}"
fi
sudo rm -rf ~/.pm2
echo -e "${g}pm2 删除成功${n}"

echo -e "${b}------------------- Pm2 卸载 完成 -------------------${n}"