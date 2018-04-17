#!/bin/bash

set -e

for st in $*; do
    git subtree split --prefix="$st" --branch="$st/master"
    git push -f "$st/AndrewCooper" "$st/master":master
done
