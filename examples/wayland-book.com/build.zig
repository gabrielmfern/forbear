const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const waylandBook = b.addModule("wayland-book", .{
        .root_source_file = b.path("src/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    const forbear = b.dependency("forbear", .{
        .target = target,
        .optimize = optimize,
    });
    waylandBook.addImport("forbear", forbear.module("forbear"));

    const exe = b.addExecutable(.{
        .name = "wayland-book.com",
        .root_module = waylandBook,
        .use_llvm = true,
    });
    b.installArtifact(exe);

    const runCommand = b.addRunArtifact(exe);
    runCommand.step.dependOn(b.getInstallStep());

    const runStep = b.step("run", "Run the example");
    runStep.dependOn(&runCommand.step);
}
