#!/bin/bash

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

source /home/woo/.env

# 检查 Vault 是否已解封
echo -e "${b}检查 Vault 是否已解封...${n}"
if ! vault status > /dev/null 2>&1; then echo -e "${r}错误: Vault 未解封，请先解封 Vault${n}"; exit 1; fi

echo -e "${b}登录 Vault...${n}"
vault login "$WHOOSHING_VAULT_ROOT_TOKEN" > /dev/null 2>&1 || { echo "${r}发生错误: vault 登陆失败！${n}" >&2; exit 1; }