#!/bin/sh
echo -ne '\033c\033]0;nairu\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/nairu.x86_64" "$@"
