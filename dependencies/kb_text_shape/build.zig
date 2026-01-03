const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "kb_text_shape",
        .root_module = b.addModule("kb_text_shape", .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .static,
    });

    lib.addIncludePath(b.path("."));
    lib.addCSourceFile(.{
        .file = b.path("kb_text_shape.c"),
        .flags = &.{
            "-fno-sanitize=alignment",
            "-fno-sanitize=shift",
            "-fno-sanitize=pointer-overflow",
        },
    });

    lib.installHeader(b.path("kb_text_shape.h"), "kb_text_shape.h");

    b.installArtifact(lib);
}
