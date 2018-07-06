#!/bin/bash
#set -x 

PWD=$(dirname $(readlink -f "$0"))
BASE="$(<$PWD/.base)"
DEPS="$PWD/.deps"
BRANCH="$(git symbolic-ref --short HEAD)"

git reset --hard "$BRANCH-base"
while IFS=' ' read -r line
do
    echo $line

    merge=$(git merge \
    --no-ff \
    --log \
    --stat \
    --rerere-autoupdate \
    -m"Merge topic branch $line onto $BRANCH" \
    $line 2>&1)

    if [[ 0 -ne $? ]]
    then
        if $(git rerere diff)
        then
            git commit --no-edit > /dev/null 2>&1
        else
            exit 1
        fi
    fi
done < "$DEPS"

git clean -dxff ansible-playbook/roles
