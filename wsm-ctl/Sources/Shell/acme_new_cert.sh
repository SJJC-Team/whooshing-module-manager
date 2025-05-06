# domain port wildcard force

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

acme="/root/.acme.sh/acme.sh"

echo -e ${b}正在颁发证书...${n}
if ! $acme --issue --dns dns_cf -d $domain ${wildcard:+-d *.$domain} --keylength ec-256 ${force:+--force}; then
    exit 1
fi
echo -e ${g}证书颁发成功${n}

mkdir -p $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs

echo -e ${b}正在安装证书...${n}
if ! $acme --install-cert --ecc -d $domain ${wildcard:+-d *.$domain} --key-file $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs/key.pem  --fullchain-file $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs/chain.crt --ca-file $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs/ca.crt; then
    exit 2
fi
echo -e ${g}证书安装成功${n}