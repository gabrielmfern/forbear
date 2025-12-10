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
    forbear.linkSystemLibrary("wayland-client", .{});
    forbear.linkSystemLibrary("wayland-egl", .{});
    forbear.linkSystemLibrary("wayland-cursor", .{});
    forbear.linkSystemLibrary("xkbcommon", .{});
    forbear.linkSystemLibrary("vulkan", .{});

    const wf = b.addWriteFiles();
    const xdg_shell_c_cmd = b.addSystemCommand(&.{
        "wayland-scanner",
        "private-code",
        "/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml",
    });
    const xdg_shell_c_file = xdg_shell_c_cmd.addOutputFileArg("xdg-shell-protocol.c");
    const xdg_shell_protocol_c_path = wf.addCopyFile(xdg_shell_c_file, "xdg-shell-protocol.c");

    const xdg_shell_h_cmd = b.addSystemCommand(&.{
        "wayland-scanner",
        "client-header",
        "/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml",
    });
    const xdg_shell_h_file = xdg_shell_h_cmd.addOutputFileArg("xdg-shell-client-protocol.h");
    _ = wf.addCopyFile(xdg_shell_h_file, "xdg-shell-client-protocol.h");

    forbear.addIncludePath(wf.getDirectory());
    forbear.addCSourceFile(.{
        .file = xdg_shell_protocol_c_path,
        .flags = &.{},
    });

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
