#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

echo -e "${b}------------------- Nvm 初始化 -------------------${n}"

echo -e "${b}1. 清除 NVM_DIR 变量${n}"
unset NVM_DIR

echo -e "${b}2. 下载并安装 nvm${n}"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

echo -e "${b}3. 复制 nvm.sh 到 /usr/local/bin${n}"
sudo cp "$(dirname "$0")/nvm.sh" /usr/local/bin/nvm
sudo chmod +x /usr/local/bin/nvm

echo -e "${b}4. 移除旧的 nvm 目录并移动新的 nvm 目录${n}"
sudo rm -rf /usr/local/nvm
sudo mv /root/.nvm /usr/local/nvm

echo -e "${b}5. 安装并使用 Node.js 版本 23${n}"
nvm install 23
nvm use 23

echo -e "${b}6. 更新用户的 .bashrc 文件${n}"
for user_dir in /home/* /root; do
    user_bashrc="$user_dir/.bashrc"
    if ! grep -q ". nvm use 23" "$user_bashrc"; then
        echo -e "${g}更新 $user_bashrc${n}"
        echo -e "\n. nvm use 23" >> "$user_bashrc"
    fi
    sed -i '/export NVM_DIR=/d' "$user_bashrc"
    sed -i '/# This loads nvm$/d' "$user_bashrc"
    sed -i '/# This loads nvm bash_completion$/d' "$user_bashrc"
done

echo -e "${b}7. 重新加载 /root/.bashrc${n}"
source /root/.bashrc

echo -e "${b}------------------- Nvm 初始化 完成 -------------------${n}"