#!/bin/bash

set -e

# 卸载 vapor
echo -e "${b}卸载 vapor(若已安装)...${n}"
sudo "$(dirname "$0")/uninstall_vapor.sh"

# 卸载 pm2
# echo -e "${b}卸载 pm2(若已安装)...${n}"
# sudo "$(dirname "$0")/uninstall_pm2.sh"

# 卸载 nvm
echo -e "${b}卸载 nvm(若已安装)...${n}"
sudo "$(dirname "$0")/uninstall_nvm.sh"
