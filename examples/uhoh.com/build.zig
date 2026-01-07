const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const uhoh = b.addModule("uhoh", .{
        .root_source_file = b.path("src/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    const forbear = b.dependency("forbear", .{
        .target = target,
        .optimize = optimize,
    });
    uhoh.addImport("forbear", forbear.module("forbear"));

    const exe = b.addExecutable(.{
        .name = "uhoh.com",
        .root_module = uhoh,
    });
    b.installArtifact(exe);

    const run_command = b.addRunArtifact(exe);
    run_command.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_command.step);
}
