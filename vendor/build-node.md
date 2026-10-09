<!-- later, we should move this to a BUILD.md instructions for other people to use, too -->

first, clone:
```bash
git submodule update --init --depth 1 vendor/node
cd vendor/node
```

for linux:
```bash
export CFLAGS="-include $PWD/../old-libm.h" CXXFLAGS="-include $PWD/../old-libm.h"
./configure --ninja
make
```

for macos:
```bash
./configure --ninja
make
```

for windows:
```bash
.\vcbuild dll
```
