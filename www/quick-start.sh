#!/bin/sh
set -eu
languages="jai c"

printf 'Project name (untitled-program): '
read -r dir < /dev/tty
dir=${dir:-untitled-program}
printf 'Language: %s (jai): ' "$(echo $languages | sed 's/ /, /g')"
read -r language < /dev/tty
language=${language:-jai}
case " $languages " in *" $language "*) ;; *) echo "Unknown language '$language', expected one of: $languages" >&2; exit 1 ;; esac

base=https://raw.githubusercontent.com/gabrielmfern/forbear/${FORBEAR_REF:-main}
release=https://github.com/gabrielmfern/forbear/releases/download/snapshot
os=$(uname -s | sed 's/Darwin/darwin/; s/Linux/linux/')
if [ "$language" = jai ]; then main=main.jai; forbear=modules/forbear; else main=main.c; forbear=forbear; fi

mkdir -p "$dir/$forbear"
cd "$dir"
curl -fsSL --create-dirs -o "$main" "$base/quick-start/$language/$main" -o Inter.ttf "$base/Inter.ttf"
curl -fsSL "$release/forbear-$language-$os.tar.gz" | tar -xz -C "$forbear"
if [ "$language" = c ]; then
  curl -fsSL -o build.sh "$base/quick-start/c/build.sh"
  chmod +x build.sh
fi

echo "Run: cd $dir"
if [ "$language" = jai ]; then
  echo "     jai main.jai +forbear"
else
  echo "     ./build.sh"
fi
