const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "nanosvg",
        .root_module = b.addModule("nanosvg", .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .static,
    });

    lib.root_module.addIncludePath(b.path("."));
    lib.root_module.addCSourceFile(.{
        .file = b.path("nanosvg.c"),
        .flags = &.{},
    });

    lib.installHeader(b.path("nanosvg.h"), "nanosvg.h");
    lib.installHeader(b.path("nanosvgrast.h"), "nanosvgrast.h");

    b.installArtifact(lib);
}
