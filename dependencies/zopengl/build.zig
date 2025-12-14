const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    _ = b.addModule("root", .{
        .root_source_file = b.path("src/zopengl.zig"),
    });

    {
        const test_step = b.step("test", "Run zopengl tests");

        const tests = b.addTest(.{
            .name = "zopengl-tests",
            .root_module = b.createModule(.{
                .root_source_file = b.path("src/zopengl.zig"),
                .target = target,
                .optimize = optimize,
            }),
        });
        b.installArtifact(tests);

        test_step.dependOn(&b.addRunArtifact(tests).step);
    }

    const lib = b.addLibrary(.{
        .name = "zopengl",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/zopengl.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    _ = b.installArtifact(lib);
}
