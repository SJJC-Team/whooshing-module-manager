#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

# 授权 src 文件夹中的所有 sh 文件
echo -e "${b}正在授权 src 文件夹中的所有 sh 文件...${n}"
find "$(dirname "$0")" -type f -name "*.sh" -exec chmod +x {} \;
echo -e "${g}授权完成${n}"

sudo mkdir -p /root/configs
cd /root/configs

echo -e "${b}克隆仓库...${n}"
git clone https://github.com/SJJC-Team/whooshing-module-manager.git
cd whooshing-module-manager/env_init

echo -e "${b}设置 init_env.sh 和 uninstall.sh 的可执行权限...${n}"
chmod +x src/init_all.sh
chmod +x src/uninstall.sh

echo -e "${b}运行卸载程序...${n}"
sudo src/uninstall.sh

echo -e "${b}运行初始化程序...${n}"
sudo src/init_all.sh

echo -e "${b}清理...${n}"
sudo rm -rf /root/configs/whooshing-module-manager

echo -e "${g}环境初始化完成.${n}"