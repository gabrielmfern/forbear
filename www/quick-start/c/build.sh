#!/bin/sh
set -eu
cd "$(dirname "$0")"
if [ "$(uname -s)" = Darwin ]; then
  cc -std=c11 -g main.c forbear/forbear.dylib -Wl,-rpath,@executable_path/forbear -o main
else
  cc -std=c11 -g main.c -Lforbear -l:forbear.so -Wl,-rpath,'$ORIGIN/forbear' -o main
fi
