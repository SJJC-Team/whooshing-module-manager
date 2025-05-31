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
    return                      301 https://\$host\$request_uri;
}

server {
    listen                      443 ssl;
    server_name                 $domain;

    ssl_certificate             $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs/chain.crt;
    ssl_certificate_key         $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs/key.pem;
    ssl_trusted_certificate     $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs/ca.crt;
    
    location / {
        proxy_pass              http://localhost:$port;
        
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_set_header X-Forwarded-Scheme \$scheme;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
    
        proxy_request_buffering off;
        proxy_read_timeout 86400s;
        client_max_body_size 0;

        # Websocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
    }
}${wildcard:+"

server {
    listen                      80;
    server_name                 *.$domain;
    return                      301 https://\$host\$request_uri;
}

server {
    listen                      443 ssl;
    server_name                 *.$domain;

    ssl_certificate             $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs/chain.crt;
    ssl_certificate_key         $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs/key.pem;
    ssl_trusted_certificate     $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs/ca.crt;

    location / {
        proxy_pass              http://localhost:$port;

        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Port \$server_port;
        proxy_set_header X-Forwarded-Scheme \$scheme;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header Host \$host;
    
        proxy_request_buffering off;
        proxy_read_timeout 86400s;
        client_max_body_size 0;

        # Websocket
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \$connection_upgrade;
    }
}"}
EOF

echo -e ${g}Nginx 配置完成: $WHOOSHING_NGINX_DIR/$domain.conf${n}