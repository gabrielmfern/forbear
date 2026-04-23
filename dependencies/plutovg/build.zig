const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "plutovg",
        .root_module = b.addModule("plutovg", .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .static,
    });

    lib.root_module.addIncludePath(b.path("include"));
    lib.root_module.addIncludePath(b.path("source"));

    const sources = &[_][]const u8{
        "source/plutovg-blend.c",
        "source/plutovg-canvas.c",
        "source/plutovg-font.c",
        "source/plutovg-matrix.c",
        "source/plutovg-paint.c",
        "source/plutovg-path.c",
        "source/plutovg-rasterize.c",
        "source/plutovg-surface.c",
        "source/plutovg-ft-math.c",
        "source/plutovg-ft-raster.c",
        "source/plutovg-ft-stroker.c",
    };

    const flags = &[_][]const u8{
        "-std=c11",
        "-DPLUTOVG_BUILD_STATIC",
    };

    for (sources) |src| {
        lib.root_module.addCSourceFile(.{
            .file = b.path(src),
            .flags = flags,
        });
    }

    if (target.result.os.tag != .windows) {
        lib.root_module.linkSystemLibrary("m", .{});
    }

    lib.installHeader(b.path("include/plutovg.h"), "plutovg.h");

    b.installArtifact(lib);
}
