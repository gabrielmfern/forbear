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
        const kb_text_shape = b.dependency("kb_text_shape", .{});
        const zmath = b.dependency("zmath", .{
            .target = target,
            .optimize = optimize,
        });
        const stb_image = b.dependency("stb_image", .{});

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
                const vulkanSdk = module.owner.graph.environ_map.get("VULKAN_SDK") orelse
                    @panic("VULKAN_SDK environment variable not set. Install the Vulkan SDK from https://vulkan.lunarg.com/");
                module.addIncludePath(.{ .cwd_relative = module.owner.fmt("{s}/Include", .{vulkanSdk}) });
                module.addLibraryPath(.{ .cwd_relative = module.owner.fmt("{s}/Lib", .{vulkanSdk}) });
            },
            else => {},
        }

        module.linkLibrary(self.freetype.artifact("freetype"));
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
                module.linkFramework("CoreGraphics", .{});
            },
            .windows => {
                module.linkSystemLibrary("user32", .{});
                module.linkSystemLibrary("kernel32", .{});
                module.linkSystemLibrary("gdi32", .{});
                module.linkSystemLibrary("psapi", .{});
            },
            else => {},
        }
        // Windows SDK ships vulkan-1.lib, not vulkan.lib
        switch (self.target.result.os.tag) {
            .windows => module.linkSystemLibrary("vulkan-1", .{}),
            else => module.linkSystemLibrary("vulkan", .{}),
        }
    }
};

const BuildContext = struct {
    dependencies: Dependencies,
    forbear: *std.Build.Module,
};

pub fn addShaderImport(b: *std.Build, module: *std.Build.Module, path: []const u8, name: []const u8) void {
    // Step 1: Compile GLSL to SPIR-V
    const glslangValidatorCommand = b.addSystemCommand(&.{ "glslangValidator", "-V", "-o" });
    const unoptimizedSpirv = glslangValidatorCommand.addOutputFileArg(std.fs.path.basename(path));
    glslangValidatorCommand.addFileArg(b.path(path));

    // Step 2: Optimize SPIR-V
    const spirvOptCommand = b.addSystemCommand(&.{ "spirv-opt", "-O", "-o" });
    const basename = std.fs.path.basename(path);
    const optimizedName = b.fmt("optimized_{s}", .{basename});
    const optimizedSpirv = spirvOptCommand.addOutputFileArg(optimizedName);
    spirvOptCommand.addFileArg(unoptimizedSpirv);

    // Step 3: Use optimized SPIR-V
    module.addAnonymousImport(
        name,
        .{ .root_source_file = optimizedSpirv },
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

    forbear.addCSourceFile(.{
        .file = b.path("src/vendor.c"),
        .flags = &.{
            "-fno-sanitize=alignment",
            "-fno-sanitize=shift",
            "-fno-sanitize=pointer-overflow",
        },
    });
    forbear.addIncludePath(dependencies.kb_text_shape.path("."));
    forbear.addIncludePath(dependencies.stb_image.path("."));

    const translateC = b.addTranslateC(.{
        .root_source_file = b.path("src/vendor.h"),
        .target = target,
        .optimize = optimize,
    });
    translateC.defineCMacro(switch (target.result.os.tag) {
        .linux => "LINUX",
        .macos => "MACOS",
        .windows => "WINDOWS",
        else => @panic("Unsupported OS"),
    }, "1");
    translateC.addIncludePath(dependencies.freetype.path("include"));
    translateC.addIncludePath(dependencies.kb_text_shape.path("."));
    translateC.addIncludePath(dependencies.stb_image.path("."));
    switch (target.result.os.tag) {
        .linux => {
            translateC.addSystemIncludePath(.{ .cwd_relative = "/usr/include" });
            translateC.addSystemIncludePath(.{ .cwd_relative = "/usr/local/include" });
            translateC.linkSystemLibrary("wayland-client", .{});
            translateC.linkSystemLibrary("wayland-cursor", .{});
            translateC.linkSystemLibrary("xkbcommon", .{});
            translateC.linkSystemLibrary("vulkan", .{});
        },
        .macos => translateC.addSystemIncludePath(.{ .cwd_relative = "/usr/local/include" }),
        .windows => {
            const vulkanSdk = b.graph.environ_map.get("VULKAN_SDK") orelse
                @panic("VULKAN_SDK environment variable not set. Install the Vulkan SDK from https://vulkan.lunarg.com/");
            translateC.addSystemIncludePath(.{ .cwd_relative = b.fmt("{s}/Include", .{vulkanSdk}) });
        },
        else => {},
    }
    if (target.result.os.tag == .macos) {
        const sdkPathRaw = b.run(&.{ "xcrun", "--show-sdk-path" });
        const sdkPath = std.mem.trim(u8, sdkPathRaw, " \n\t");
        translateC.addSystemFrameworkPath(.{ .cwd_relative = b.fmt("{s}/System/Library/Frameworks", .{sdkPath}) });
    }

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
        translateC.addIncludePath(wf.getDirectory());
    }

    forbear.addImport("c", translateC.createModule());

    addShaderImport(b, forbear, "shaders/element/vertex.vert", "element_vertex_shader");
    addShaderImport(b, forbear, "shaders/element/fragment.frag", "element_fragment_shader");
    addShaderImport(b, forbear, "shaders/text/vertex.vert", "text_vertex_shader");
    addShaderImport(b, forbear, "shaders/text/fragment.frag", "text_fragment_shader");
    addShaderImport(b, forbear, "shaders/shadow/vertex.vert", "shadow_vertex_shader");
    addShaderImport(b, forbear, "shaders/shadow/fragment.frag", "shadow_fragment_shader");

    forbear.addAnonymousImport("inter_font", .{ .root_source_file = b.path("Inter.ttf") });

    return .{
        .dependencies = dependencies,
        .forbear = forbear,
    };
}

fn addPlaygroundExecutable(
    b: *std.Build,
    moduleName: []const u8,
    executableName: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    forbear: *std.Build.Module,
    dependencies: *Dependencies,
) *std.Build.Step.Compile {
    const playground = b.addModule(moduleName, .{
        .root_source_file = b.path("playground.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });

    dependencies.addToModule(playground);
    playground.addImport("forbear", forbear);

    return b.addExecutable(.{
        .name = executableName,
        .root_module = playground,
    });
}

fn addUhohExecutable(
    b: *std.Build,
    moduleName: []const u8,
    executableName: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    forbear: *std.Build.Module,
) *std.Build.Step.Compile {
    const uhoh = b.addModule(moduleName, .{
        .root_source_file = b.path("examples/uhoh.com/src/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    uhoh.addImport("forbear", forbear);

    return b.addExecutable(.{
        .name = executableName,
        .root_module = uhoh,
    });
}

fn addWaylandBookExecutable(
    b: *std.Build,
    moduleName: []const u8,
    executableName: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    forbear: *std.Build.Module,
) *std.Build.Step.Compile {
    const waylandBook = b.addModule(moduleName, .{
        .root_source_file = b.path("examples/wayland-book.com/src/main.zig"),
        .link_libc = true,
        .target = target,
        .optimize = optimize,
    });
    waylandBook.addImport("forbear", forbear);

    return b.addExecutable(.{
        .name = executableName,
        .root_module = waylandBook,
    });
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const defaultContext = createForbearModule(b, "forbear", target, optimize);
    const forbear = defaultContext.forbear;
    var dependencies = defaultContext.dependencies;

    const testFilterOption = b.option([]const u8, "test-filter", "Only run tests whose names contain this string");
    const testDebugOption = b.option(bool, "test-debug", "Generate a debuggable test executable") orelse false;
    const modTests = b.addTest(.{
        .root_module = forbear,
        .filters = if (testFilterOption) |filter| &.{filter} else &.{},
        .test_runner = .{ .path = b.path("test_runner.zig"), .mode = .simple },
    });
    const testStep = b.step("test", "Run tests");
    if (testDebugOption) {
        const installTests = b.addInstallArtifact(modTests, .{});
        testStep.dependOn(&installTests.step);
    } else {
        const runModTests = b.addRunArtifact(modTests);
        testStep.dependOn(&runModTests.step);
    }

    // Benchmarks
    {
        const benchModule = b.createModule(.{
            .root_source_file = b.path("bench.zig"),
            .target = target,
            .optimize = optimize,
        });
        benchModule.addImport("forbear", forbear);

        const install = b.option(bool, "install", "Install benchmark executable instead of running it") orelse false;

        const benchExe = b.addExecutable(.{
            .name = "bench",
            .root_module = benchModule,
        });
        const benchStep = b.step("bench", "Run benchmarks");
        if (install) {
            const installBench = b.addInstallArtifact(benchExe, .{});
            benchStep.dependOn(&installBench.step);
        } else {
            const runBench = b.addRunArtifact(benchExe);
            if (b.args) |args| runBench.addArgs(args);
            benchStep.dependOn(&runBench.step);
        }
    }

    {
        // Playground
        const playgroundExe = addPlaygroundExecutable(
            b,
            "playground",
            "playground",
            target,
            optimize,
            forbear,
            &dependencies,
        );
        b.installArtifact(playgroundExe);

        const runPlaygroundCommand = b.addRunArtifact(playgroundExe);
        runPlaygroundCommand.step.dependOn(b.getInstallStep());

        const runPlaygroundStep = b.step("run", "Run the playground");
        runPlaygroundStep.dependOn(&runPlaygroundCommand.step);
    }

    // Stress tests — `zig build stress-<name>`
    {
        const stress_tests = [_]struct { name: []const u8, path: []const u8, desc: []const u8 }{
            .{ .name = "stress-text-cache-misses", .path = "stress/text-cache-misses.zig", .desc = "Stress test: constant glyph cache misses from rotating unicode blocks and font sizes" },
        };

        for (stress_tests) |t| {
            const mod = b.addModule(t.name, .{
                .root_source_file = b.path(t.path),
                .link_libc = true,
                .target = target,
                .optimize = optimize,
            });
            dependencies.addToModule(mod);
            mod.addImport("forbear", forbear);
            mod.addAnonymousImport("inter_font", .{ .root_source_file = b.path("Inter.ttf") });

            const exe = b.addExecutable(.{
                .name = t.name,
                .root_module = mod,
            });

            const runCmd = b.addRunArtifact(exe);

            const step = b.step(t.name, t.desc);
            step.dependOn(&runCmd.step);
        }
    }

    // Check step - builds all examples and playground
    {
        const checkStep = b.step("check", "Build all examples and playground");

        // Build playground
        const playgroundExe = addPlaygroundExecutable(
            b,
            "playground_check",
            "playground_check",
            target,
            optimize,
            forbear,
            &dependencies,
        );
        checkStep.dependOn(&playgroundExe.step);

        // Build uhoh.com and wayland-book.com examples.
        // On non-Windows, run standalone builds to exercise each example's own build.zig.
        // On Windows, Vulkan SDK import library resolution fails inside child zig-build
        // processes, so compile the example sources directly through the root build instead.
        if (target.result.os.tag != .windows) {
            const uhohBuild = b.addSystemCommand(&.{ "zig", "build" });
            uhohBuild.setCwd(b.path("examples/uhoh.com"));
            checkStep.dependOn(&uhohBuild.step);

            const waylandBookBuild = b.addSystemCommand(&.{ "zig", "build" });
            waylandBookBuild.setCwd(b.path("examples/wayland-book.com"));
            checkStep.dependOn(&waylandBookBuild.step);
        } else {
            const uhohCheck = addUhohExecutable(
                b,
                "uhoh_check",
                "uhoh_check",
                target,
                optimize,
                forbear,
            );
            checkStep.dependOn(&uhohCheck.step);

            const waylandBookCheck = addWaylandBookExecutable(
                b,
                "wayland_book_check",
                "wayland_book_check",
                target,
                optimize,
                forbear,
            );
            checkStep.dependOn(&waylandBookCheck.step);
        }
    }

    // Package step - builds debug executables and copies them for CI upload
    {
        const packageStep = b.step("package", "Build and package debug executables");
        const packageDirectory: std.Build.InstallDir = .{ .custom = "pr-binaries" };
        const packageContext = createForbearModule(b, "forbear_package", target, .Debug);
        var packageDependencies = packageContext.dependencies;
        const packagePlaygroundExe = addPlaygroundExecutable(
            b,
            "playground_package",
            "playground",
            target,
            .Debug,
            packageContext.forbear,
            &packageDependencies,
        );
        const packageUhohExe = addUhohExecutable(
            b,
            "uhoh_package",
            "uhoh.com",
            target,
            .Debug,
            packageContext.forbear,
        );

        const installPlaygroundBinary = b.addInstallFileWithDir(
            packagePlaygroundExe.getEmittedBin(),
            packageDirectory,
            packagePlaygroundExe.out_filename,
        );
        const installUhohBinary = b.addInstallFileWithDir(
            packageUhohExe.getEmittedBin(),
            packageDirectory,
            packageUhohExe.out_filename,
        );

        packageStep.dependOn(&installPlaygroundBinary.step);
        packageStep.dependOn(&installUhohBinary.step);
    }
}
