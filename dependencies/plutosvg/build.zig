const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const plutovg = b.dependency("plutovg", .{
        .target = target,
        .optimize = optimize,
    });

    const lib = b.addLibrary(.{
        .name = "plutosvg",
        .root_module = b.addModule("plutosvg", .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .static,
    });

    lib.root_module.addIncludePath(b.path("source"));
    lib.root_module.addIncludePath(plutovg.path("include"));

    const flags = &[_][]const u8{
        "-std=c99",
        "-DPLUTOSVG_BUILD",
        "-DPLUTOSVG_BUILD_STATIC",
    };

    lib.root_module.addCSourceFile(.{
        .file = b.path("source/plutosvg.c"),
        .flags = flags,
    });

    lib.root_module.linkLibrary(plutovg.artifact("plutovg"));

    if (target.result.os.tag != .windows) {
        lib.root_module.linkSystemLibrary("m", .{});
    }

    lib.installHeader(b.path("source/plutosvg.h"), "plutosvg.h");

    b.installArtifact(lib);
}
