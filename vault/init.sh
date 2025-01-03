#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

read_integer() {
    local label=$1; local default=$2; local max=$3
    while true; do
        read -p $label segment; segment=${segment:-$default}
        if [[ "$segment" =~ ^[0-9]+$ ]] && [ "$segment" -gt 0 ] && [ "$segment" -lt $max ]; then echo $segment; break
        else echo -e "${r}请输入一个有效的正整数！(0><$max)${n}" >&2; fi
    done
}

if [[ $1 = -n ]]; then noenter=true; else noenter=false; fi

echo -e "${b}------------------- Vault 初始化 -------------------${n}"

# 安装 vault
if [[ $noenter = true ]]; then ans=y;
else read -p "从头安装?(y/n): " ans; fi
if [[ $ans = y ]]; then
    echo -e "${b}安装 vault:${n}"
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install vault
    echo -e "${g}Vault 安装完成${n}"
fi
sudo cp vault.hcl /etc/vault.d/vault.hcl
echo -e "${g}Vault 配置文件已复制${n}"

# 启动服务
sudo systemctl restart vault
echo -e "${g}Vault 服务已重启${n}"

# 初始化
if [[ $noenter = true ]]; then segment=5;
else segment=$(read_integer "主密钥切片数量(5): " 5 100); fi
echo -e "${g}你选择的主密钥分片数量是：$segment${n}"
if [[ $noenter = true ]]; then threshold=4;
else threshold=$(read_integer "解密所需的最少切片数量(4): " 4 $segment); fi
echo -e "${g}你选择的主密钥最少解密数量是：$threshold${n}"
export VAULT_ADDR='unix:///opt/vault/vault.sock'
set +e; vault_output=$(vault operator init -key-shares=$segment -key-threshold=$threshold 2>&1)
keys=($(echo "$vault_output" | grep -oP 'Unseal Key \d+: \K[^\n]+'))
root_token=$(echo "$vault_output" | grep -oP 'Initial Root Token: \K.*'); set -e
if [[ ${#keys[@]} != $segment ]] || [[ ! $root_token ]]; then
    echo -e "${r}$vault_output${n}"; exit 1
fi
if [[ $noenter = false ]]; then
    echo -e "${b}请记下您的主密钥切片，以及 root 令牌:${n}"
    echo -e "\n${b}Unseal Keys:${n}"; for key in "${keys[@]}"; do echo "$key"; done
    echo -e "\n${b}Initial Root Token:${n}"; echo -e "$root_token\n"
    read -p "按回车继续..."
fi

# 解封
for ((i=0; i<$threshold; i++)); do
    echo -e "\n${b}使用密钥 ${keys[$i]} 解封 ($((i+1))/$threshold):${n}\n"
    vault operator unseal ${keys[$i]}
done
echo -e "\n${g}Vault 已成功解封${n}"
if [[ $noenter = true ]]; then
    echo -e "${g}请记下您的主密钥切片，以及 root 令牌:${n}"
    echo -e "\n${b}Unseal Keys:${n}"; for key in "${keys[@]}"; do echo "$key"; done
    echo -e "\n${b}Initial Root Token:${n}"; echo -e "$root_token\n"
    read -p "按回车继续..."
fi
echo -e "${b}------------------- Vault 初始化 完成 -------------------${n}"