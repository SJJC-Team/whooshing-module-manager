#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

echo -e "${b}------------------- Vapor 初始化 -------------------${n}"

mkdir -p /root/configs
cd /root/configs

# 安装 Swiftly
echo -e "${b}正在安装 Swiftly...${n}"
expect << EOF
spawn bash -c "curl -L https://swiftlang.github.io/swiftly/swiftly-install.sh | bash"
expect "Please select the platform to use for toolchain downloads:" { send "1\r" }
expect "Select one of the following:" { send "2\r" }
expect "Enter the swiftly data and configuration files directory" { send "/usr/local/swiftly\r"}
expect "Enter the swiftly executables installation directory" { send "/usr/local/bin/swiftly\r" }
expect "Modify login config" { send "n\r" }
expect "Install system dependencies?" {send "Y\r"}
expect "Select one of the following:" { send "1\r" }
expect eof
EOF
echo -e "${g}Swiftly 安装成功${n}"

. /usr/local/swiftly/env.sh

echo -e "${b}检查 swiftly 安装路径...${n}"
if [ -d "/usr/local/bin/swiftly" ]; then
    echo -e "${b}swiftly 安装路径存在${n}"
    if [ ! -f /etc/profile.d/swiftly.sh ]; then sudo touch /etc/profile.d/swiftly.sh; fi
    if ! grep -q "/usr/local/bin/swiftly" /etc/profile.d/swiftly.sh; then
        echo -e "${b}将 swiftly 路径添加到系统环境变量中...${n}"
        echo "export PATH=\$PATH:/usr/local/bin/swiftly" | sudo tee -a /etc/profile.d/swiftly.sh
        source /etc/profile.d/swiftly.sh
        echo -e "${g}swiftly 路径已添加${n}"
    else echo -e "${g}swiftly 路径已存在于系统环境变量中${n}"; fi
else
    echo -e "${r}swiftly 安装失败${n}"; exit 1
fi

# 安装 Swift
echo -e "${b}正在安装最新版本的 Swift...${n}"
swiftly install latest

# 测试 swift 是否安装
if ! command -v swift &> /dev/null; then echo -e "${r}Swift 安装失败${n}"; exit 1
else echo -e "${g}Swift 安装成功${n}"; fi

# 检查 vapor 是否已安装
echo -e "${b}检查 Vapor 是否已安装...${n}"
if ! command -v vapor &> /dev/null; then
    echo -e "${b}Vapor 未安装，正在安装 Vapor Toolbox...${n}"
    git clone https://github.com/vapor/toolbox.git
    cd toolbox
    git checkout 18.7.5
    make install
    echo -e "${g}Vapor 安装成功${n}"
else echo -e "${g}Vapor 已安装${n}"; fi

echo -e "${b}------------------- Vapor 初始化 完成 -------------------${n}"