# module port key

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

data_dir="$WHOOSHING_DATA_DIR/$module/percona/$port"

export PATH=/usr/lib/postgresql/17/bin:$PATH
conf_file="$data_dir/postgresql.conf"

# 初始化数据库
echo -e "${b}初始化数据库...${n}"
sudo -u woo env "PATH=$PATH" pg_ctl init -D "$data_dir"
sudo -u woo echo "listen_addresses = 'localhost'" >> "$conf_file"
sudo -u woo echo "shared_preload_libraries=pg_tde" >> "$conf_file"
sudo -u woo echo "port = $port" >> "$conf_file"
sudo -u woo env "PATH=$PATH" pg_ctl start -D "$data_dir" -l $data_dir/log

# 创建扩展 - pg_tde
echo -e "${b}创建扩展 - pg_tde...${n}"
sudo -u woo psql -d template1 -p $port -U woo -c "DROP DATABASE postgres;"
sudo -u woo psql -d template1 -p $port -U woo -c "CREATE EXTENSION pg_tde;"
sudo -u woo psql -d template1 -p $port -U woo -c "SELECT pg_tde_add_key_provider_vault_v2('vault-provider','$WHOOSHING_VAULT_ROOT_TOKEN','$VAULT_ADDR', '$module', NULL);"
sudo -u woo psql -d template1 -p $port -U woo -c "SELECT pg_tde_set_principal_key('$port/tde/template1', 'vault-provider');"

# 设置密码
echo -e "${b}设置密码...${n}"
sudo -u woo psql -d template1 -p $port -U woo -c "ALTER USER woo WITH PASSWORD '$key';"

# 修改配置文件
echo -e "${b}修改配置文件...${n}"
rm -f $data_dir/pg_hba.conf
cp "$(dirname "$0")/pg_hba.conf" $data_dir/pg_hba.conf

chown -R woo:whooshing "$data_dir"
chmod -R 700 "$data_dir"