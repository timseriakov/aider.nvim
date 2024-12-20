#!/bin/bash

target_file=./lua/telescope/_extensions/model_data.lua

echo 'return {' >$target_file

# this is outputting some empty "" entries, can you filter those out ai!
aider --models e | grep '^- ' | sed -e 's/^- /  "/' -e 's/$/",/' | grep -v '^  "",$' >>$target_file

echo '}' >>$target_file
