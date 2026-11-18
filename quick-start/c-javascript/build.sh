#!/bin/sh
set -eu
cd "$(dirname "$0")"
npm run build
if [ "$(uname -s)" = Darwin ]; then
  cc -std=c23 -g main.c forbear/forbear-javascript.dylib -Wl,-rpath,@executable_path/forbear -Wl,-rpath,@executable_path -o main
else
  cc -std=c23 -g main.c -Lforbear -l:forbear-javascript.so -Wl,--disable-new-dtags -Wl,-rpath,'$ORIGIN/forbear:$ORIGIN/lib' -o main
fi
