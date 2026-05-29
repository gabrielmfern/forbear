const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "tree-sitter",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .static,
    });
    lib.root_module.addIncludePath(b.path("include"));
    lib.root_module.addIncludePath(b.path("src"));
    lib.root_module.addCMacro("_DEFAULT_SOURCE", "1");
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

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("include/tree_sitter/api.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    translate_c.addIncludePath(b.path("include"));

    const ts_module = b.addModule("tree-sitter", .{
        .root_source_file = translate_c.getOutput(),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    ts_module.linkLibrary(lib);
}
