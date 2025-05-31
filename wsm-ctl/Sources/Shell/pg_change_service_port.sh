# module p port_base

set -e

port=$(($port_base + $p))
data_dir="$WHOOSHING_DATA_DIR/$module/percona/$p"
conf_file="$data_dir/postgresql.conf"

export PATH=/usr/lib/postgresql/17/bin:$PATH

sudo -u woo sed -i '/^port=/d' "$conf_file"
sudo -u woo echo "port = $port" >> "$conf_file"

exit 0
