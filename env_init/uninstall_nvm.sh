#!/bin/bash

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

echo -e "${b}------------------- Nvm 卸载 -------------------${n}"

echo -e "${b}1. 删除 nvm 工具${n}"
sudo rm -f /usr/local/bin/nvm
sudo rm -rf /usr/local/nvm

echo -e "${b}2. 更新用户的 .bashrc 文件${n}"
for user_dir in /home/* /root; do
    user_bashrc="$user_dir/.bashrc"
    sed -i '/. nvm use 23/d' "$user_bashrc"
done

echo -e "${b}------------------- Nvm 卸载 完成 -------------------${n}"