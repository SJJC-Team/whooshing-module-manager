# url name des

mkdir -p $GITHUB_DIR
wget "${url}/releases/latest/download/${name}.tar.gz" -O "${des}/${name}.tar.gz"
tar -xzvf "${des}/${name}.tar.gz" -C "${des}"

exit 0