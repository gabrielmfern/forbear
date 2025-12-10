const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const forbear = b.addModule("forbear", .{
        .root_source_file = b.path("src/root.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    forbear.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
    forbear.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
    forbear.linkSystemLibrary("vulkan", .{ .needed = true });

    const mod_tests = b.addTest(.{
        .root_module = forbear,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    {
        const playground = b.createModule(.{
            .root_source_file = b.path("playground.zig"),
            .link_libc = true,
            .target = target,
            .optimize = optimize,
        });
        playground.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
        playground.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
        playground.linkSystemLibrary("vulkan", .{ .needed = true });
        playground.addImport("forbear", forbear);

        // Playground
        const playground_exe = b.addExecutable(.{
            .name = "playground",
            .root_module = playground,
        });
        b.installArtifact(playground_exe);

        const run_playground_command = b.addRunArtifact(playground_exe);
        run_playground_command.step.dependOn(b.getInstallStep());

        const run_playground_step = b.step("run", "Run the playground");
        run_playground_step.dependOn(&run_playground_command.step);
    }
}
