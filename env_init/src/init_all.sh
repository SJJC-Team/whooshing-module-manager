#!/bin/bash

# 安装 expect
echo -e "${b}检查 expect 是否已安装...${n}"
if ! command -v expect &> /dev/null; then
    echo -e "${b}expect 未安装，正在安装 expect...${n}"
    sudo apt-get update
    sudo apt-get install expect -y
    echo -e "${g}expect 安装成功${n}"
else echo -e "${g}expect 已安装${n}"; fi

# 授权 src 文件夹中的所有 sh 文件
echo -e "${b}正在授权 src 文件夹中的所有 sh 文件...${n}"
find "$(dirname "$0")" -type f -name "*.sh" -exec chmod +x {} \;
echo -e "${g}授权完成${n}"

# 安装 nvm
echo -e "${b}检查 nvm 是否已安装...${n}"
if command -v nvm &> /dev/null; then
    echo -e "${b}nvm 已安装${n}"
    sudo "$(dirname "$0")/uninstall_nvm.sh"
fi
sudo "$(dirname "$0")/init_nvm.sh"

# 安装 pm2
echo -e "${b}检查 pm2 是否已安装...${n}"
if ! command -v pm2 &> /dev/null; then
    echo -e "${b}pm2 未安装，正在安装 pm2...${n}"
    sudo "$(dirname "$0")/init_pm2.sh"
else echo -e "${g}pm2 已安装${n}"; fi

# 安装 vapor
echo -e "${b}检查 vapor 是否已安装...${n}"
if ! command -v vapor &> /dev/null; then
    echo -e "${b}vapor 未安装，正在安装 vapor...${n}"
    sudo "$(dirname "$0")/init_vapor.sh"
else echo -e "${g}vapor 已安装${n}"; fi