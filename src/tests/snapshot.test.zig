const std = @import("std");

const forbear = @import("../root.zig");
const snapshot = @import("../snapshot.zig");
const utilities = @import("utilities.zig");

fn runSnapshotTest(snapshotName: []const u8, buildFn: *const fn () anyerror!void) !void {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        try buildFn();
        const node = try forbear.layout();
        try snapshot.expectMatchesSnapshot(std.testing.allocator, node, snapshotName);
    });
}

fn buildSimpleHorizontalLayout() !void {
    forbear.element(.{
        .direction = .leftToRight,
        .width = .{ .fixed = 120.0 },
        .height = .{ .fixed = 40.0 },
    })({
        forbear.element(.{
            .width = .{ .fixed = 10.0 },
            .height = .{ .fixed = 10.0 },
        })({});
        forbear.element(.{
            .width = .{ .fixed = 20.0 },
            .height = .{ .fixed = 15.0 },
        })({});
        forbear.element(.{
            .width = .{ .fixed = 30.0 },
            .height = .{ .fixed = 20.0 },
        })({});
    });
}

fn buildVerticalPaddingMarginBorderLayout() !void {
    forbear.element(.{
        .direction = .topToBottom,
        .width = .{ .fixed = 100.0 },
        .height = .{ .fixed = 100.0 },
        .padding = .{
            .x = .{ 3.0, 3.0 },
            .y = .{ 4.0, 4.0 },
        },
        .borderWidth = .{
            .x = .{ 1.0, 1.0 },
            .y = .{ 2.0, 2.0 },
        },
    })({
        forbear.element(.{
            .width = .{ .fixed = 40.0 },
            .height = .{ .fixed = 10.0 },
            .margin = .{
                .x = .{ 2.0, 0.0 },
                .y = .{ 1.0, 3.0 },
            },
        })({});
        forbear.element(.{
            .width = .{ .fixed = 30.0 },
            .height = .{ .fixed = 20.0 },
            .margin = .{
                .x = .{ 0.0, 4.0 },
                .y = .{ 2.0, 1.0 },
            },
        })({});
    });
}

fn buildNestedFitContainers() !void {
    forbear.element(.{
        .direction = .topToBottom,
        .width = .fit,
        .height = .fit,
        .padding = forbear.Padding.all(2.0),
    })({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .fit,
            .height = .fit,
            .padding = forbear.Padding.inLine(1.0),
        })({
            forbear.element(.{
                .width = .{ .fixed = 30.0 },
                .height = .{ .fixed = 10.0 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 15.0 },
                .height = .{ .fixed = 20.0 },
            })({});
        });
    });
}

fn buildWordWrappingTextLayout() !void {
    forbear.element(.{
        .direction = .topToBottom,
        .width = .{ .fixed = 70.0 },
        .height = .fit,
        .textWrapping = .word,
    })({
        forbear.text("hello world from forbear");
    });
}

fn buildMixedAlignmentLayout() !void {
    forbear.element(.{
        .direction = .leftToRight,
        .alignment = .bottomCenter,
        .width = .{ .fixed = 120.0 },
        .height = .{ .fixed = 60.0 },
    })({
        forbear.element(.{
            .width = .{ .fixed = 15.0 },
            .height = .{ .fixed = 10.0 },
        })({});
        forbear.element(.{
            .width = .{ .fixed = 25.0 },
            .height = .{ .fixed = 20.0 },
        })({});
    });
}

fn buildManualAndStandardFlowLayout() !void {
    forbear.element(.{
        .direction = .leftToRight,
        .width = .{ .fixed = 100.0 },
        .height = .{ .fixed = 40.0 },
    })({
        forbear.element(.{
            .width = .{ .fixed = 20.0 },
            .height = .{ .fixed = 15.0 },
        })({});
        forbear.element(.{
            .placement = .{ .manual = .{ 45.0, 7.0 } },
            .width = .{ .fixed = 18.0 },
            .height = .{ .fixed = 10.0 },
        })({});
        forbear.element(.{
            .width = .{ .fixed = 12.0 },
            .height = .{ .fixed = 15.0 },
        })({});
    });
}

fn buildGrowChildrenLayout() !void {
    forbear.element(.{
        .direction = .leftToRight,
        .width = .{ .fixed = 100.0 },
        .height = .{ .fixed = 30.0 },
    })({
        forbear.element(.{
            .width = .{ .fixed = 10.0 },
            .height = .grow,
        })({});
        forbear.element(.{
            .width = .grow,
            .height = .grow,
        })({});
        forbear.element(.{
            .width = .grow,
            .height = .grow,
        })({});
    });
}

fn buildPercentageChildrenLayout() !void {
    forbear.element(.{
        .direction = .topToBottom,
        .width = .{ .fixed = 200.0 },
        .height = .{ .fixed = 100.0 },
    })({
        forbear.element(.{
            .width = .{ .percentage = 0.5 },
            .height = .{ .percentage = 0.25 },
        })({});
        forbear.element(.{
            .direction = .leftToRight,
            .width = .{ .percentage = 0.5 },
            .height = .{ .percentage = 0.5 },
        })({
            forbear.element(.{
                .width = .{ .percentage = 0.5 },
                .height = .grow,
            })({});
        });
    });
}

test "snapshot - simple horizontal layout" {
    try runSnapshotTest("simple_horizontal_layout", buildSimpleHorizontalLayout);
}

test "snapshot - vertical padding margin border layout" {
    try runSnapshotTest("vertical_padding_margin_border_layout", buildVerticalPaddingMarginBorderLayout);
}

test "snapshot - nested fit containers" {
    try runSnapshotTest("nested_fit_containers", buildNestedFitContainers);
}

test "snapshot - word wrapping text layout" {
    try runSnapshotTest("word_wrapping_text_layout", buildWordWrappingTextLayout);
}

test "snapshot - mixed alignment layout" {
    try runSnapshotTest("mixed_alignment_layout", buildMixedAlignmentLayout);
}

test "snapshot - manual and standard flow layout" {
    try runSnapshotTest("manual_and_standard_flow_layout", buildManualAndStandardFlowLayout);
}

test "snapshot - grow children layout" {
    try runSnapshotTest("grow_children_layout", buildGrowChildrenLayout);
}

test "snapshot - percentage children layout" {
    try runSnapshotTest("percentage_children_layout", buildPercentageChildrenLayout);
}
