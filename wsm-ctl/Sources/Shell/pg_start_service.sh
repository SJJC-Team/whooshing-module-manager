# data_dir

set -e

export PATH=/usr/lib/postgresql/17/bin:$PATH

sudo -u woo env "PATH=$PATH" pg_ctl start -D "$data_dir" -l "$data_dir/log"