# port key

set -e

export PATH=/usr/lib/postgresql/17/bin:$PATH

res=$(sudo -u woo PGPASSWORD=$key psql -d template1 -p $port -U woo -t -A -c "SELECT oid AS "OID", datname AS "Database" FROM pg_database WHERE datistemplate = false;")

echo -n $res