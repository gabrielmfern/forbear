#!/bin/sh
set -eu
languages="jai c"
adapters="none javascript"

printf 'Project name (untitled-program): '
read -r dir < /dev/tty
dir=${dir:-untitled-program}
printf 'Language: %s (jai): ' "$(echo $languages | sed 's/ /, /g')"
read -r language < /dev/tty
language=${language:-jai}
case " $languages " in *" $language "*) ;; *) echo "Unknown language '$language', expected one of: $languages" >&2; exit 1 ;; esac
printf 'Adapter: %s (none): ' "$(echo $adapters | sed 's/ /, /g')"
read -r adapter < /dev/tty
adapter=${adapter:-none}
case " $adapters " in *" $adapter "*) ;; *) echo "Unknown adapter '$adapter', expected one of: $adapters" >&2; exit 1 ;; esac

base=https://raw.githubusercontent.com/gabrielmfern/forbear/${FORBEAR_REF:-main}
release=https://github.com/gabrielmfern/forbear/releases/download/snapshot
os=$(uname -s | sed 's/Darwin/darwin/; s/Linux/linux/')
template=$language
[ "$adapter" = none ] || template=$language-$adapter
if [ "$language" = jai ]; then main=main.jai; forbear=modules/forbear; else main=main.c; forbear=forbear; fi

mkdir -p "$dir/$forbear"
cd "$dir"
curl -fsSL --create-dirs -o "$main" "$base/quick-start/$template/$main" -o Inter.ttf "$base/Inter.ttf"
curl -fsSL "$release/forbear-$language-$os.tar.gz" | tar -xz -C "$forbear"
if [ "$adapter" = javascript ]; then
  curl -fsSL --create-dirs \
    -o package.json "$base/quick-start/$template/package.json" \
    -o tsconfig.json "$base/quick-start/$template/tsconfig.json" \
    -o src/index.tsx "$base/quick-start/javascript/src/index.tsx"
  node=.
  [ "$language" = jai ] && node=modules/forbear/vendor/node/out/Release
  mkdir -p "$node"
  curl -fsSL "$release/libnode-$os.tar.gz" | tar -xz -C "$node"
fi

echo "Run: cd $dir"
[ "$adapter" = javascript ] && echo "     npm install"
if [ "$language" = jai ]; then
  echo "     jai main.jai +forbear"
else
  library=forbear
  [ "$adapter" = javascript ] && echo "     npm run build" && library=forbear-javascript
  extension=so
  [ "$os" = darwin ] && extension=dylib
  echo "     cc -std=c23 main.c forbear/$library.$extension -Wl,-rpath,'\$ORIGIN/forbear' -o main"
fi
