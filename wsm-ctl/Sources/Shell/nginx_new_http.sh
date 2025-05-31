# domain port wildcard

set -e

r='\033[31m'
g='\033[32m'
b='\033[34m'
n='\033[0m'

truncate -s 0 $WHOOSHING_NGINX_DIR/$domain.conf

echo -e ${b}正在配置 Nginx 文件...${n}
cat << EOF > $WHOOSHING_NGINX_DIR/$domain.conf
# Domain = $domain${wildcard:+, *.$domain}

server {
    listen                      80;
    server_name                 $domain;
    
    location / {
        proxy_pass              http://localhost:$port;
    }
}${wildcard:+"

server {
    listen                      80;
    server_name                 *.$domain;

    location / {
        proxy_pass              http://localhost:$port;
    }
}"}
EOF

echo -e ${g}Nginx 配置完成: $WHOOSHING_NGINX_DIR/$domain.conf${n}