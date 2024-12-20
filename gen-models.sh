#!/bin/bash

target_file=./lua/telescope/_extensions/model_data.lua

echo 'return {' >$target_file

aider --models e | grep '^- ' | sed -e 's/^- /  "/' -e 's/$/",/' | grep -v '^  "",$' >>$target_file

echo '}' >>$target_file
