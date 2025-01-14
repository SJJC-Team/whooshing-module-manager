# data_dir

set -e

export PATH=/usr/lib/postgresql/17/bin:$PATH

sudo systemctl restart postgresql.service

sudo -u woo env "PATH=$PATH" pg_ctl restart -D "$data_dir" -l "$data_dir/log"