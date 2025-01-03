export NVM_DIR="/usr/local/nvm/dir" &&
export PATH="/usr/local/nvm:$PATH" &&
export NODE_OPTIONS="--no-warnings" &&
. /usr/local/nvm/nvm.sh &&
unset NPM_CONFIG_PREFIX &&
if expr "$1" : '^[0-9]\+\.[0-9]\+\.[0-9]\+$' >/dev/null; then
    nvm use $1>/dev/null &&
    shift &&
    export NODE_PATH=$(npm root -g) &&
    node $@
else
    nvm $@ &&
    export NODE_PATH=$(npm root -g)
fi