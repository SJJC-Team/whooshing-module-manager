#!/bin/bash

function delete_key() {
    IFS=$'\n' values=($(vault kv list -format=json "$1" | jq -r '.[]'))

    if [ -z "$values" ]; then
        printf '\n%s\n' "$(vault kv delete "$1")"
    fi
    return
}

function traverse_delete {
    local -r path="$1"
    result=$(vault kv list -format=json "$path" 2>&1)

    status=$?
    if [ ! $status -eq 0 ]; then
        if [[ $result =~ "permission denied" ]]; then
            return
        fi
        >&2 && [ ! "Z$result" == "Z{}" ] && echo "$result"
    fi

    for secret in $(echo "$result" | jq -r '.[]'); do
        if [[ "$secret" == */ ]]; then
            traverse_delete "$path$secret"
        else
            printf '%s\t%s' "找到密钥:" "$path$secret"
            delete_key "$path$secret"
        fi
    done
}

# MAIN Iterate on all kv secrets or start from the path provided by the input ARG[1]
if [[ "$1" ]]; then
    # Make sure the path always ends with '/'
    search_path=("${1%"/"}/")
fi

echo "### 删除 $search_path 下的所有密钥"
for _s_path in $search_path; do
    traverse_delete "${_s_path}"
done
