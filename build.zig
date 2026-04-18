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

const BuildContext = struct {
    dependencies: Dependencies,
    forbear: *std.Build.Module,
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

fn createForbearModule(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) BuildContext {
    const forbear = b.addModule(name, .{
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
            Protocol{
                .name = "xdg-decoration-unstable-v1",
                .xmlPath = "/usr/share/wayland-protocols/unstable/xdg-decoration/xdg-decoration-unstable-v1.xml",
            },
        };
        const wf = b.addWriteFiles();
        inline for (waylandProtocols) |protocol| {
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

            forbear.addCSourceFile(.{ .file = protocolCPath, .flags = &.{} });
        }
        forbear.addIncludePath(wf.getDirectory());
    }

    addShaderImport(b, forbear, "shaders/element/vertex.vert", "element_vertex_shader");
    addShaderImport(b, forbear, "shaders/element/fragment.frag", "element_fragment_shader");
    addShaderImport(b, forbear, "shaders/text/vertex.vert", "text_vertex_shader");
    addShaderImport(b, forbear, "shaders/text/fragment.frag", "text_fragment_shader");
    addShaderImport(b, forbear, "shaders/shadow/vertex.vert", "shadow_vertex_shader");
    addShaderImport(b, forbear, "shaders/shadow/fragment.frag", "shadow_fragment_shader");

    return .{
        .dependencies = dependencies,
        .forbear = forbear,
    };
}

fn addPlaygroundExecutable(
    b: *std.Build,
    module_name: []const u8,
    executable_name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    forbear: *std.Build.Module,
    dependencies: *Dependencies,
) *std.Build.Step.Compile {
    const playground = b.addModule(module_name, .{
        .root_source_file = b.path("playground.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    dependencies.addToModule(playground);
    playground.addImport("forbear", forbear);

    return b.addExecutable(.{
        .name = executable_name,
        .root_module = playground,
        .use_llvm = true,
    });
}

fn addUhohExecutable(
    b: *std.Build,
    module_name: []const u8,
    executable_name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    forbear: *std.Build.Module,
) *std.Build.Step.Compile {
    const uhoh = b.addModule(module_name, .{
        .root_source_file = b.path("examples/uhoh.com/src/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    uhoh.addImport("forbear", forbear);

    return b.addExecutable(.{
        .name = executable_name,
        .root_module = uhoh,
        .use_llvm = true,
    });
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const default_context = createForbearModule(b, "forbear", target, optimize);
    const forbear = default_context.forbear;
    var dependencies = default_context.dependencies;

    const testFilterOption = b.option([]const u8, "test-filter", "Only run tests whose names contain this string");
    const mod_tests = b.addTest(.{
        .root_module = forbear,
        .filters = if (testFilterOption) |filter| &.{filter} else &.{},
        .test_runner = .{ .path = b.path("test_runner.zig"), .mode = .simple },
    });
    const run_mod_tests = b.addRunArtifact(mod_tests);
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);

    // Benchmarks
    {
        const zbench_dep = b.dependency("zbench", .{ .target = target, .optimize = optimize });
        const bench_module = b.createModule(.{
            .root_source_file = b.path("src/tests/bench.zig"),
            .target = target,
            .optimize = optimize,
        });
        bench_module.addImport("forbear", forbear);
        bench_module.addImport("zbench", zbench_dep.artifact("zbench").root_module);

        const bench_exe = b.addTest(.{
            .root_module = bench_module,
            .test_runner = .{ .path = b.path("test_runner.zig"), .mode = .simple },
        });
        const run_bench = b.addRunArtifact(bench_exe);
        const bench_step = b.step("bench", "Run benchmarks");
        bench_step.dependOn(&run_bench.step);
    }

    {
        // Playground
        const playground_exe = addPlaygroundExecutable(
            b,
            "playground",
            "playground",
            target,
            optimize,
            forbear,
            &dependencies,
        );
        b.installArtifact(playground_exe);

        const run_playground_command = b.addRunArtifact(playground_exe);
        run_playground_command.step.dependOn(b.getInstallStep());

        const run_playground_step = b.step("run", "Run the playground");
        run_playground_step.dependOn(&run_playground_command.step);
    }

    // Check step - builds all examples and playground
    {
        const check_step = b.step("check", "Build all examples and playground");

        // Build playground
        const playground_exe = addPlaygroundExecutable(
            b,
            "playground_check",
            "playground_check",
            target,
            optimize,
            forbear,
            &dependencies,
        );
        check_step.dependOn(&playground_exe.step);

        // Build uhoh.com example
        const uhoh_build = b.addSystemCommand(&.{
            "zig",
            "build",
        });
        uhoh_build.setCwd(b.path("examples/uhoh.com"));
        check_step.dependOn(&uhoh_build.step);
    }

    // Package step - builds debug executables and copies them for CI upload
    {
        const package_step = b.step("package", "Build and package debug executables");
        const package_directory: std.Build.InstallDir = .{ .custom = "pr-binaries" };
        const package_context = createForbearModule(b, "forbear_package", target, .Debug);
        var package_dependencies = package_context.dependencies;
        const package_playground_exe = addPlaygroundExecutable(
            b,
            "playground_package",
            "playground",
            target,
            .Debug,
            package_context.forbear,
            &package_dependencies,
        );
        const package_uhoh_exe = addUhohExecutable(
            b,
            "uhoh_package",
            "uhoh.com",
            target,
            .Debug,
            package_context.forbear,
        );

        const install_playground_binary = b.addInstallFileWithDir(
            package_playground_exe.getEmittedBin(),
            package_directory,
            package_playground_exe.out_filename,
        );
        const install_uhoh_binary = b.addInstallFileWithDir(
            package_uhoh_exe.getEmittedBin(),
            package_directory,
            package_uhoh_exe.out_filename,
        );

        package_step.dependOn(&install_playground_binary.step);
        package_step.dependOn(&install_uhoh_binary.step);
    }
}
