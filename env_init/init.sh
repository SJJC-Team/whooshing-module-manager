#!/bin/bash

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

echo -e "${b}Creating /root/configs directory...${n}"
sudo mkdir -p /root/configs

echo -e "${b}Changing to /root/configs directory...${n}"
cd /root/configs

echo -e "${b}Cloning the repository...${n}"
git clone https://github.com/SJJC-Team/whooshing-module-manager.git

echo -e "${b}Changing to whooshing-module-manager/env_init directory...${n}"
cd whooshing-module-manager/env_init

echo -e "${b}Setting execute permissions for init_env.sh and uninstall.sh...${n}"
chmod +x src/init_all.sh
chmod +x src/uninstall.sh

echo -e "${b}Running uninstall.sh...${n}"
sudo src/uninstall.sh

echo -e "${b}Running init_all.sh...${n}"
sudo src/init_all.sh

echo -e "${b}Cleaning up...${n}"
sudo rm -rf /root/configs/whooshing-module-manager

echo -e "${g}Environment initialization complete!${n}"