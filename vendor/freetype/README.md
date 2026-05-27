# freetype packaged for the Zig build system

This is a fork of [freetype](https://gitlab.freedesktop.org/freetype/freetype), packaged for Zig. Unnecessary files have been deleted, and the build system has been replaced with build.zig.

_Looking for Zig bindings to Freetype?_ See [mach/freetype](https://github.com/hexops/mach-freetype).

## Updating

To update this repository, run `./update.sh` followed by `./verify.sh` to verify the repository contents.

## Verifying repository contents

For supply chain security reasons (e.g. to confirm we made no patches to the code) we provide a `git diff` command you can run to verify the contents of this repository:

```sh
./verify.sh
```

If nothing is printed, there is no diff. Deleted files, and changes to `README.md`, `build.zig`, `.github` CI files and `.gitignore` are ignored.

## Issues

Issues are tracked in the [main Mach repository](https://github.com/hexops/mach/issues?q=is%3Aissue+is%3Aopen+label%3Afreetype).
