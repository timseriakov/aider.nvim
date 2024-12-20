#!/bin/bash

target_file=./lua/telescope/_extensions/model_data.lua

echo 'return {' >$target_file

get_models() {
  search_pattern="$1"
  aider --models "$search_pattern" |
    grep '^- ' |
    sed -e 's/^- /  "/' -e 's/$/",/' |
    grep -v '^  "",$' >>$target_file
}

echo "$(get_models e)$(get_models i)" | sort | uniq >>$target_file

echo '}' >>$target_file
