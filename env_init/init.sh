#!/bin/bash

# 安装 expect
echo -e "${b}检查 expect 是否已安装...${n}"
if ! command -v expect &> /dev/null; then
    echo -e "${b}expect 未安装，正在安装 expect...${n}"
    sudo apt-get update
    sudo apt-get install expect -y
    echo -e "${g}expect 安装成功${n}"
else echo -e "${g}expect 已安装${n}"; fi