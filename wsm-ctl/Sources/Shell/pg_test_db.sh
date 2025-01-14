# port database key

set -e

export PATH=/usr/lib/postgresql/17/bin:$PATH

if ! sudo -u woo PGPASSWORD=$key psql -d $database -p $port -U woo -c "SELECT 1"; then exit 1; fi