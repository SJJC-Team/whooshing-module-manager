# domain wildcard

set -e

acme="/root/.acme.sh/acme.sh"

if ! $acme --remove -d $domain ${wildcard:+-d *.$domain}; then
    exit 1
fi

rm -rf $WHOOSHING_NGINX_DIR/certs/$domain.ssl-certs

rm -f /etc/nginx_sites/$domain.conf