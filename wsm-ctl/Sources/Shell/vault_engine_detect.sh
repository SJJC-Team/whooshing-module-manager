# module

set -e

if ! res=$(vault kv list "$module" 2>/dev/null); then exit 1; fi

exit 0
