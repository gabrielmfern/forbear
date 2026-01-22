const std = @import("std");

const Dependencies = struct {
    freetype: *std.Build.Dependency,
    kb_text_shape: *std.Build.Dependency,
    zmath: *std.Build.Dependency,
    stb_image: *std.Build.Dependency,

    target: std.Build.ResolvedTarget,

    fn init(
        b: *std.Build,
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
    ) @This() {
        const freetype = b.dependency("freetype", .{
            .target = target,
            .optimize = optimize,
        });
        const kb_text_shape = b.dependency("kb_text_shape", .{
            .target = target,
            .optimize = optimize,
        });
        const zmath = b.dependency("zmath", .{
            .target = target,
            .optimize = optimize,
        });
        const stb_image = b.dependency("stb_image", .{
            .target = target,
            .optimize = optimize,
        });

        return @This(){
            .freetype = freetype,
            .kb_text_shape = kb_text_shape,
            .stb_image = stb_image,
            .zmath = zmath,
            .target = target,
        };
    }

    fn addToModule(
        self: *@This(),
        module: *std.Build.Module,
    ) void {
        switch (self.target.result.os.tag) {
            .linux, .macos => {
                module.addIncludePath(.{ .cwd_relative = "/usr/local/include" });
                module.addLibraryPath(.{ .cwd_relative = "/usr/local/lib" });
            },
            .windows => {
                module.addIncludePath(.{ .cwd_relative = "C:/VulkanSDK/1.4.335.0/Include" });
                module.addLibraryPath(.{ .cwd_relative = "C:/VulkanSDK/1.4.335.0/Lib" });
            },
            else => {},
        }

        module.linkLibrary(self.freetype.artifact("freetype"));
        module.linkLibrary(self.kb_text_shape.artifact("kb_text_shape"));
        module.linkLibrary(self.stb_image.artifact("stb_image"));
        module.addImport("zmath", self.zmath.module("root"));

        switch (self.target.result.os.tag) {
            .linux => {
                module.linkSystemLibrary("wayland-client", .{});
                module.linkSystemLibrary("wayland-cursor", .{});
                module.linkSystemLibrary("xkbcommon", .{});
            },
            .macos => {
                module.linkFramework("Cocoa", .{});
                module.linkFramework("Metal", .{});
                module.linkFramework("QuartzCore", .{});
            },
            .windows => {
                module.linkSystemLibrary("user32", .{});
                module.linkSystemLibrary("kernel32", .{});
                module.linkSystemLibrary("gdi32", .{});
            },
            else => {},
        }
        module.linkSystemLibrary("vulkan", .{});
    }
};

pub fn addShaderImport(b: *std.Build, module: *std.Build.Module, path: []const u8, name: []const u8) void {
    // Step 1: Compile GLSL to SPIR-V
    const glslangValidatorCommand = b.addSystemCommand(&.{ "glslangValidator", "-V", "-o" });
    const unoptimized_spirv = glslangValidatorCommand.addOutputFileArg(std.fs.path.basename(path));
    glslangValidatorCommand.addFileArg(b.path(path));

    // Step 2: Optimize SPIR-V
    const spirvOptCommand = b.addSystemCommand(&.{ "spirv-opt", "-O", "-o" });
    const basename = std.fs.path.basename(path);
    const optimized_name = b.fmt("optimized_{s}", .{basename});
    const optimized_spirv = spirvOptCommand.addOutputFileArg(optimized_name);
    spirvOptCommand.addFileArg(unoptimized_spirv);

    // Step 3: Use optimized SPIR-V
    module.addAnonymousImport(
        name,
        .{ .root_source_file = optimized_spirv },
    );
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const forbear = b.addModule("forbear", .{
        .root_source_file = b.path("src/root.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    var dependencies = Dependencies.init(b, target, optimize);

    dependencies.addToModule(forbear);

    if (target.result.os.tag == .linux) {
        const Protocol = struct {
            name: []const u8,
            xmlPath: []const u8,
        };
        const waylandProtocols = comptime [_]Protocol{
            Protocol{
                .name = "xdg-shell",
                .xmlPath = "/usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml",
            },
            Protocol{
                .name = "fractional-scale-v1",
                .xmlPath = "/usr/share/wayland-protocols/staging/fractional-scale/fractional-scale-v1.xml",
            },
            Protocol{
                .name = "viewporter",
                .xmlPath = "/usr/share/wayland-protocols/stable/viewporter/viewporter.xml",
            },
        };
        inline for (waylandProtocols) |protocol| {
            const wf = b.addWriteFiles();
            const cCommand = b.addSystemCommand(&.{
                "wayland-scanner",
                "private-code",
                protocol.xmlPath,
            });
            const cFile = cCommand.addOutputFileArg(protocol.name ++ "-protocol.c");
            const protocolCPath = wf.addCopyFile(cFile, protocol.name ++ "-protocol.c");

            const headerCommand = b.addSystemCommand(&.{
                "wayland-scanner",
                "client-header",
                protocol.xmlPath,
            });
            const headerFile = headerCommand.addOutputFileArg(protocol.name ++ "-client-protocol.h");
            _ = wf.addCopyFile(headerFile, protocol.name ++ "-client-protocol.h");

            forbear.addIncludePath(wf.getDirectory());
            forbear.addCSourceFile(.{ .file = protocolCPath, .flags = &.{} });
        }
    }

    addShaderImport(b, forbear, "shaders/element/vertex.vert", "element_vertex_shader");
    addShaderImport(b, forbear, "shaders/element/fragment.frag", "element_fragment_shader");
    addShaderImport(b, forbear, "shaders/text/vertex.vert", "text_vertex_shader");
    addShaderImport(b, forbear, "shaders/text/fragment.frag", "text_fragment_shader");
    addShaderImport(b, forbear, "shaders/shadow/vertex.vert", "shadow_vertex_shader");
    addShaderImport(b, forbear, "shaders/shadow/fragment.frag", "shadow_fragment_shader");

    const mod_tests = b.addTest(.{
        .root_module = forbear,
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    {
        // Playground
        const playground = b.addModule("playground", .{
            .root_source_file = b.path("playground.zig"),
            .link_libc = true,
            .target = target,
            .optimize = optimize,
        });

        dependencies.addToModule(playground);

        playground.addImport("forbear", forbear);

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
