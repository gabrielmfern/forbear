const std = @import("std");

const LayoutGlyph = @import("node.zig").LayoutGlyph;
const Node = @import("node.zig").Node;

const SnapshotNodeKind = enum {
    root,
    child,
};

fn writeIndent(writer: anytype, indent: usize) !void {
    for (0..indent) |_| {
        try writer.writeAll("  ");
    }
}

fn writeNodeLine(
    writer: anytype,
    node: *const Node,
    indent: usize,
    kind: SnapshotNodeKind,
    index: usize,
) !void {
    try writeIndent(writer, indent);
    switch (kind) {
        .root => try writer.print(
            "[root] pos=({d:.1}, {d:.1}) size=({d:.1}, {d:.1}) z={d}\n",
            .{ node.position[0], node.position[1], node.size[0], node.size[1], node.z },
        ),
        .child => try writer.print(
            "[child-{d}] pos=({d:.1}, {d:.1}) size=({d:.1}, {d:.1}) z={d}\n",
            .{ index, node.position[0], node.position[1], node.size[0], node.size[1], node.z },
        ),
    }
}

fn writeGlyphLine(writer: anytype, glyph: LayoutGlyph, indent: usize, index: usize) !void {
    try writeIndent(writer, indent);
    try writer.print(
        "[glyph-{d}] pos=({d:.1}, {d:.1}) index={d} text=\"{s}\"\n",
        .{ index, glyph.position[0], glyph.position[1], glyph.index, glyph.text },
    );
}

fn serializeNode(
    writer: anytype,
    node: *const Node,
    indent: usize,
    kind: SnapshotNodeKind,
    index: usize,
) !void {
    try writeNodeLine(writer, node, indent, kind, index);
    switch (node.children) {
        .nodes => |nodes| {
            for (nodes.items, 0..) |*child, childIndex| {
                try serializeNode(writer, child, indent + 1, .child, childIndex);
            }
        },
        .glyphs => |glyphs| {
            for (glyphs.slice, 0..) |glyph, glyphIndex| {
                try writeGlyphLine(writer, glyph, indent + 1, glyphIndex);
            }
        },
    }
}

pub fn serializeTree(writer: anytype, node: *const Node, indent: usize) !void {
    try serializeNode(writer, node, indent, .root, 0);
}

fn snapshotPath(allocator: std.mem.Allocator, snapshotName: []const u8) ![]u8 {
    return try std.fmt.allocPrint(allocator, "tests/snapshots/{s}.expected", .{snapshotName});
}

fn shouldUpdateSnapshots(allocator: std.mem.Allocator) !bool {
    const updateValue = std.process.getEnvVarOwned(allocator, "UPDATE_SNAPSHOTS") catch |err| switch (err) {
        error.EnvironmentVariableNotFound => return false,
        else => return err,
    };
    defer allocator.free(updateValue);
    return std.mem.eql(u8, updateValue, "1");
}

pub fn expectMatchesSnapshot(
    allocator: std.mem.Allocator,
    node: *const Node,
    snapshotName: []const u8,
) !void {
    var serialized: std.ArrayList(u8) = .empty;
    defer serialized.deinit(allocator);

    try serializeTree(serialized.writer(allocator), node, 0);

    const path = try snapshotPath(allocator, snapshotName);
    defer allocator.free(path);

    try std.fs.cwd().makePath("tests/snapshots");
    if (try shouldUpdateSnapshots(allocator)) {
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();
        try file.writeAll(serialized.items);
        return;
    }

    const expected = try std.fs.cwd().readFileAlloc(allocator, path, std.math.maxInt(usize));
    defer allocator.free(expected);
    try std.testing.expectEqualStrings(expected, serialized.items);
}
