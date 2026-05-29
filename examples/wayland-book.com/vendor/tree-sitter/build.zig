const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "tree-sitter",
        .root_module = b.addModule("tree-sitter", .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .static,
    });
    // The public API lives in include/; lib.c references the other sources and
    // their headers relative to src/.
    lib.root_module.addIncludePath(b.path("include"));
    lib.root_module.addIncludePath(b.path("src"));
    // -std=c11 sets __STRICT_ANSI__, which hides the POSIX/BSD extensions the
    // sources rely on (fdopen, and le16toh/be16toh from <endian.h>).
    // _DEFAULT_SOURCE re-exposes them.
    lib.root_module.addCMacro("_DEFAULT_SOURCE", "1");
    // lib.c is an amalgamation that #includes every other translation unit in
    // src/, so it is the only file we hand to the compiler. wasm_store.c is
    // pulled in too but is a no-op unless TREE_SITTER_FEATURE_WASM is defined,
    // which keeps us free of the wasmtime dependency.
    lib.root_module.addCSourceFile(.{
        .file = b.path("src/lib.c"),
        .flags = &.{"-std=c11"},
    });
    lib.installHeadersDirectory(
        b.path("include/tree_sitter"),
        "tree_sitter",
        .{},
    );

    b.installArtifact(lib);
}
