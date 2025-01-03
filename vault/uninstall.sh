#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

if [[ $1 = -n ]]; then noenter=true; else noenter=false; fi

echo -e "${b}------------------- Vault 卸载 -------------------${n}"

echo -e "${b}正在卸载 Vault...${n}"
sudo systemctl stop vault
expect << EOF
spawn sudo apt-get remove --purge vault
expect "Do you want to continue?" { send "Y\r" }
expect eof
EOF
sudo rm -rf /etc/vault.d
if [[ $noenter = true ]]; then ans=y
else echo -e -n "${r}删除 Vault 的数据？(y/n): ${n}"; read -p "" ans; fi
if [[ $ans = y ]]; then
    echo -e "${b}删除所有 Vault 的数据.${n}"
    sudo rm -rf /opt/vault
fi
sudo systemctl daemon-reload
echo -e "${g}Vault 已成功卸载。${n}"

echo -e "${b}------------------- Vault 卸载 完成 -------------------${n}"