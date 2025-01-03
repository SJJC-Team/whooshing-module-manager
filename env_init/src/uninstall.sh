#!/bin/bash

# 授权 src 文件夹中的所有 sh 文件
echo -e "${b}正在授权 src 文件夹中的所有 sh 文件...${n}"
find "$(dirname "$0")" -type f -name "*.sh" -exec chmod +x {} \;
echo -e "${g}授权完成${n}"

# 卸载 vapor
echo -e "${b}检查 vapor 是否已安装...${n}"
if command -v vapor &> /dev/null; then
    echo -e "${b}vapor 已安装${n}"
    sudo "$(dirname "$0")/uninstall_vapor.sh"
fi

# 卸载 pm2
echo -e "${b}检查 pm2 是否已安装...${n}"
if command -v pm2 &> /dev/null; then
    echo -e "${b}pm2 已安装${n}"
    sudo "$(dirname "$0")/uninstall_pm2.sh"
fi

# 卸载 nvm
echo -e "${b}检查 nvm 是否已安装...${n}"
if command -v nvm &> /dev/null; then
    echo -e "${b}nvm 已安装${n}"
    sudo "$(dirname "$0")/uninstall_nvm.sh"
fi