<!-- later, we should move this to a BUILD.md instructions for other people to use, too -->

First, clone:
```bash
git submodule update --init --depth 1 vendor/node
cd vendor/node
```

For Linux:
```bash
export CFLAGS="-include $PWD/../old-libm.h" CXXFLAGS="-include $PWD/../old-libm.h"
./configure --ninja --shared
make
```

For macOS:
```bash
./configure --ninja --shared
make
```

For Windows:
```bash
.\vcbuild dll
```
