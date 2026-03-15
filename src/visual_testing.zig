const std = @import("std");

const forbear = @import("root.zig");
const utilities = @import("tests/utilities.zig");

const Vec4 = @Vector(4, f32);

pub const RenderedScene = struct {
    pixels: []u8,
    width: u32,
    height: u32,
};

fn goldenPath(allocator: std.mem.Allocator, goldenName: []const u8, suffix: []const u8) ![]u8 {
    return try std.fmt.allocPrint(allocator, "tests/golden/{s}{s}.ppm", .{ goldenName, suffix });
}

fn shouldUpdateGolden(allocator: std.mem.Allocator) !bool {
    const updateValue = std.process.getEnvVarOwned(allocator, "UPDATE_GOLDEN") catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return false,
        else => return err,
    };
    defer allocator.free(updateValue);
    return std.mem.eql(u8, updateValue, "1");
}

fn encodePpm(
    allocator: std.mem.Allocator,
    pixels: []const u8,
    width: u32,
    height: u32,
) ![]u8 {
    std.debug.assert(pixels.len == @as(usize, width) * @as(usize, height) * 4);

    var encoded: std.ArrayList(u8) = .empty;
    defer encoded.deinit(allocator);

    try encoded.writer(allocator).print("P6\n{d} {d}\n255\n", .{ width, height });
    for (0..@as(usize, width) * @as(usize, height)) |pixelIndex| {
        const offset = pixelIndex * 4;
        try encoded.appendSlice(allocator, &.{
            pixels[offset],
            pixels[offset + 1],
            pixels[offset + 2],
        });
    }
    return try encoded.toOwnedSlice(allocator);
}

fn writePpmFile(
    allocator: std.mem.Allocator,
    path: []const u8,
    pixels: []const u8,
    width: u32,
    height: u32,
) !void {
    const encoded = try encodePpm(allocator, pixels, width, height);
    defer allocator.free(encoded);

    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();
    try file.writeAll(encoded);
}

pub fn renderScene(
    allocator: std.mem.Allocator,
    width: u32,
    height: u32,
    buildFn: *const fn () anyerror!void,
) !RenderedScene {
    var graphics = try forbear.Graphics.initHeadless(allocator, "forbear-visual-tests");
    defer graphics.deinit();

    var renderer = try graphics.initHeadlessRenderer(width, height);
    defer renderer.deinit();

    try forbear.init(allocator, &renderer);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var meta = try utilities.frameMeta(arenaAllocator);
    meta.viewportSize = .{ @floatFromInt(width), @floatFromInt(height) };

    try forbear.frame(meta)({
        try buildFn();
        const node = try forbear.layout();
        try renderer.drawFrame(arenaAllocator, node, Vec4{ 0.0, 0.0, 0.0, 0.0 }, .{ 72, 72 }, 0);
    });

    return .{
        .pixels = try renderer.readPixels(allocator),
        .width = width,
        .height = height,
    };
}

pub fn expectMatchesGolden(
    allocator: std.mem.Allocator,
    pixels: []const u8,
    width: u32,
    height: u32,
    goldenName: []const u8,
) !void {
    try std.fs.cwd().makePath("tests/golden");

    const targetPath = try goldenPath(allocator, goldenName, "");
    defer allocator.free(targetPath);

    if (try shouldUpdateGolden(allocator)) {
        try writePpmFile(allocator, targetPath, pixels, width, height);
        return;
    }

    const actual = try encodePpm(allocator, pixels, width, height);
    defer allocator.free(actual);

    const expected = try std.fs.cwd().readFileAlloc(allocator, targetPath, std.math.maxInt(usize));
    defer allocator.free(expected);

    if (!std.mem.eql(u8, expected, actual)) {
        const actualPath = try goldenPath(allocator, goldenName, ".actual");
        defer allocator.free(actualPath);
        try writePpmFile(allocator, actualPath, pixels, width, height);
    }

    try std.testing.expectEqualSlices(u8, expected, actual);
}
