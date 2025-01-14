# port database key

set -e

export PATH=/usr/lib/postgresql/17/bin:$PATH

sudo -u woo PGPASSWORD=$key psql -d template1 -p $port -U woo -c "DROP DATABASE $database;"