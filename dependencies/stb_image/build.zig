const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "stb_image",
        .root_module = b.addModule("stb_image", .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .static,
    });

    lib.addIncludePath(b.path("."));
    lib.addCSourceFile(.{
        .file = b.path("stb_iamge.c"),
        .flags = &.{
            "-fno-sanitize=alignment",
            "-fno-sanitize=shift",
            "-fno-sanitize=pointer-overflow",
        },
    });

    lib.installHeader(b.path("stb_image.h"), "stb_image.h");

    b.installArtifact(lib);
}
