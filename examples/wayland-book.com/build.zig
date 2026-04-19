const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const wayland_book = b.addModule("wayland-book", .{
        .root_source_file = b.path("src/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    const forbear = b.dependency("forbear", .{
        .target = target,
        .optimize = optimize,
    });
    wayland_book.addImport("forbear", forbear.module("forbear"));

    const exe = b.addExecutable(.{
        .name = "wayland-book.com",
        .root_module = wayland_book,
        .use_llvm = true,
    });
    b.installArtifact(exe);

    const run_command = b.addRunArtifact(exe);
    run_command.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_command.step);
}
