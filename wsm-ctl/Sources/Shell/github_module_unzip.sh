# name des

set -e

mkdir -p "$des"
tar -xzvf "${des}/${name}.tar.gz" -C "${des}"

exit 0
