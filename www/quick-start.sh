#!/bin/sh
set -eu
printf 'Project name (untitled-program): '
read -r dir < /dev/tty
dir=${dir:-untitled-program}
base=https://raw.githubusercontent.com/gabrielmfern/forbear/${FORBEAR_REF:-main}
os=$(uname -s | sed 's/Darwin/darwin/; s/Linux/linux/')
mkdir -p "$dir"
cd "$dir"
curl -fsSL --create-dirs \
  -o main.jai "$base/apps/quick-start.jai" \
  -o Inter.ttf "$base/apps/Inter.ttf" \
  -o modules/forbear/bindings-darwin.jai "$base/bindings-darwin.jai" \
  -o modules/forbear/bindings-linux.jai "$base/bindings-linux.jai" \
  -o modules/forbear/bindings-win32.jai "$base/bindings-win32.jai" \
  -o modules/forbear/vendor/freetype-$os.a "$base/vendor/freetype-$os.a" \
  -o modules/forbear/vendor/kb_text_shape-$os.a "$base/vendor/kb_text_shape-$os.a" \
  -o modules/forbear/module.jai "$base/forbear.jai"
echo "Run: cd $dir && jai main.jai +forbear"