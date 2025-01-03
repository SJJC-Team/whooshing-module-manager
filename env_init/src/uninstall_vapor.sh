#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

echo -e "${b}------------------- Vapor 卸载 -------------------${n}"

# 卸载 Vapor
echo -e "${b}正在卸载 Vapor...${n}"
if command -v vapor &> /dev/null; then
    sudo rm -f /usr/local/bin/vapor
    sudo rm -rf /root/configs/toolbox
    echo -e "${g}Vapor 卸载成功${n}"
else
    echo -e "${g}Vapor 未安装${n}"
fi

# 卸载 Swiftly
echo -e "${b}正在卸载 Swiftly...${n}"
sudo rm -rf /usr/local/swiftly
sudo rm -rf /usr/local/bin/swiftly
sudo rm -f /etc/profile.d/swiftly.sh
echo -e "${g}Swiftly 卸载成功${n}"

echo -e "${b}------------------- Vapor 卸载 完成 -------------------${n}"