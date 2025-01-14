# data_dir

set -e

export PATH=/usr/lib/postgresql/17/bin:$PATH

sudo -u woo env "PATH=$PATH" pg_ctl stop -D "$data_dir"