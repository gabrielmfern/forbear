const std = @import("std");

const sources = [_][]const u8{
    "src/autofit/autofit.c",
    "src/base/ftbase.c",
    "src/base/ftsystem.c",
    "src/base/ftdebug.c",
    "src/base/ftbbox.c",
    "src/base/ftbdf.c",
    "src/base/ftbitmap.c",
    "src/base/ftcid.c",
    "src/base/ftfstype.c",
    "src/base/ftgasp.c",
    "src/base/ftglyph.c",
    "src/base/ftgxval.c",
    "src/base/ftinit.c",
    "src/base/ftmm.c",
    "src/base/ftotval.c",
    "src/base/ftpatent.c",
    "src/base/ftpfr.c",
    "src/base/ftstroke.c",
    "src/base/ftsynth.c",
    "src/base/fttype1.c",
    "src/base/ftwinfnt.c",
    "src/bdf/bdf.c",
    "src/bzip2/ftbzip2.c",
    "src/cache/ftcache.c",
    "src/cff/cff.c",
    "src/cid/type1cid.c",
    "src/gzip/ftgzip.c",
    "src/lzw/ftlzw.c",
    "src/pcf/pcf.c",
    "src/pfr/pfr.c",
    "src/psaux/psaux.c",
    "src/pshinter/pshinter.c",
    "src/psnames/psnames.c",
    "src/raster/raster.c",
    "src/sdf/sdf.c",
    "src/sfnt/sfnt.c",
    "src/smooth/smooth.c",
    "src/svg/svg.c",
    "src/truetype/truetype.c",
    "src/type1/type1.c",
    "src/type42/type42.c",
    "src/winfonts/winfnt.c",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addLibrary(.{
        .name = "freetype",
        .root_module = b.addModule("freetype", .{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .linkage = .static,
    });
    lib.linkLibC();
    lib.addIncludePath(b.path("include"));
    lib.root_module.addCMacro("FT2_BUILD_LIBRARY", "1");
    lib.root_module.addCMacro("FT_CONFIG_OPTION_USE_BROTLI", "1");
    // Enable LCD/subpixel rendering support for high-quality text rendering
    // The Microsoft ClearType patents have expired (circa 2019-2020)
    lib.root_module.addCMacro("FT_CONFIG_OPTION_SUBPIXEL_RENDERING", "1");
    lib.linkLibrary(b.dependency("brotli", .{
        .target = target,
        .optimize = optimize,
    }).artifact("brotli"));

    lib.root_module.addCMacro("HAVE_UNISTD_H", "1");
    lib.addCSourceFiles(.{ .files = &sources, .flags = &.{} });
    if (target.result.os.tag == .macos) lib.addCSourceFile(.{
        .file = b.path("src/base/ftmac.c"),
        .flags = &.{},
    });
    lib.installHeadersDirectory(
        b.path("include/freetype"),
        "freetype",
        .{},
    );
    lib.installHeader(
        b.path("include/ft2build.h"),
        "ft2build.h",
    );

    b.installArtifact(lib);
}
