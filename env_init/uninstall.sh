#!/bin/bash

# 卸载 vapor
echo -e "${b}检查 vapor 是否已安装...${n}"
if command -v vapor &> /dev/null; then
    echo -e "${b}vapor 已安装${n}"
    sudo "$(dirname "$0")/src/uninstall_vapor.sh"
fi

# 卸载 pm2
echo -e "${b}检查 pm2 是否已安装...${n}"
if command -v pm2 &> /dev/null; then
    echo -e "${b}pm2 已安装${n}"
    sudo "$(dirname "$0")/src/uninstall_pm2.sh"
fi

# 卸载 nvm
echo -e "${b}检查 nvm 是否已安装...${n}"
if command -v nvm &> /dev/null; then
    echo -e "${b}nvm 已安装${n}"
    sudo "$(dirname "$0")/src/uninstall_nvm.sh"
fi