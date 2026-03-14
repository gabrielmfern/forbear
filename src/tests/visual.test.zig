const std = @import("std");

const forbear = @import("../root.zig");
const visual_testing = @import("../visual_testing.zig");

fn runVisualTest(
    goldenName: []const u8,
    width: u32,
    height: u32,
    buildFn: *const fn () anyerror!void,
) !void {
    const rendered = try visual_testing.renderScene(std.testing.allocator, width, height, buildFn);
    defer std.testing.allocator.free(rendered.pixels);

    try visual_testing.expectMatchesGolden(
        std.testing.allocator,
        rendered.pixels,
        rendered.width,
        rendered.height,
        goldenName,
    );
}

fn buildSolidColoredBoxes() !void {
    forbear.element(.{
        .direction = .leftToRight,
        .width = .{ .fixed = 96.0 },
        .height = .{ .fixed = 48.0 },
        .background = .{ .color = .{ 0.05, 0.05, 0.05, 1.0 } },
    })({
        forbear.element(.{
            .width = .{ .fixed = 24.0 },
            .height = .grow,
            .background = .{ .color = .{ 1.0, 0.0, 0.0, 1.0 } },
        })({});
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .background = .{ .color = .{ 0.0, 1.0, 0.0, 1.0 } },
        })({});
        forbear.element(.{
            .width = .{ .fixed = 24.0 },
            .height = .grow,
            .background = .{ .color = .{ 0.0, 0.0, 1.0, 1.0 } },
        })({});
    });
}

fn buildRoundedCorners() !void {
    forbear.element(.{
        .width = .{ .fixed = 80.0 },
        .height = .{ .fixed = 80.0 },
        .background = .{ .color = .{ 0.1, 0.1, 0.1, 1.0 } },
        .padding = forbear.Padding.all(10.0),
    })({
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .background = .{ .color = .{ 0.9, 0.2, 0.2, 1.0 } },
            .borderRadius = 12.0,
        })({});
    });
}

fn buildNestedPaddingAndMargin() !void {
    forbear.element(.{
        .direction = .topToBottom,
        .width = .{ .fixed = 96.0 },
        .height = .{ .fixed = 96.0 },
        .background = .{ .color = .{ 0.12, 0.12, 0.12, 1.0 } },
        .padding = forbear.Padding.all(6.0),
    })({
        forbear.element(.{
            .width = .grow,
            .height = .{ .fixed = 30.0 },
            .margin = forbear.Margin.bottom(4.0),
            .background = .{ .color = .{ 0.9, 0.8, 0.2, 1.0 } },
        })({});
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .padding = forbear.Padding.all(6.0),
            .background = .{ .color = .{ 0.2, 0.2, 0.8, 1.0 } },
        })({
            forbear.element(.{
                .width = .grow,
                .height = .grow,
                .background = .{ .color = .{ 0.8, 0.4, 0.8, 1.0 } },
            })({});
        });
    });
}

fn buildZOrdering() !void {
    forbear.element(.{
        .width = .{ .fixed = 96.0 },
        .height = .{ .fixed = 96.0 },
        .background = .{ .color = .{ 0.0, 0.0, 0.0, 0.0 } },
    })({
        forbear.element(.{
            .placement = .{ .manual = .{ 8.0, 8.0 } },
            .width = .{ .fixed = 50.0 },
            .height = .{ .fixed = 50.0 },
            .background = .{ .color = .{ 1.0, 0.0, 0.0, 0.7 } },
            .zIndex = 1,
        })({});
        forbear.element(.{
            .placement = .{ .manual = .{ 24.0, 24.0 } },
            .width = .{ .fixed = 50.0 },
            .height = .{ .fixed = 50.0 },
            .background = .{ .color = .{ 0.0, 1.0, 0.0, 0.7 } },
            .zIndex = 2,
        })({});
    });
}

fn buildTextRendering() !void {
    forbear.element(.{
        .direction = .topToBottom,
        .width = .{ .fixed = 120.0 },
        .height = .{ .fixed = 60.0 },
        .padding = forbear.Padding.all(6.0),
        .background = .{ .color = .{ 1.0, 1.0, 1.0, 1.0 } },
        .color = .{ 0.1, 0.1, 0.1, 1.0 },
        .textWrapping = .word,
        .fontSize = 14.0,
    })({
        forbear.text("Forbear visual");
    });
}

test "visual - solid colored boxes" {
    try runVisualTest("solid_colored_boxes", 96, 48, buildSolidColoredBoxes);
}

test "visual - rounded corners" {
    try runVisualTest("rounded_corners", 80, 80, buildRoundedCorners);
}

test "visual - nested padding and margin" {
    try runVisualTest("nested_padding_and_margin", 96, 96, buildNestedPaddingAndMargin);
}

test "visual - z ordering" {
    try runVisualTest("z_ordering", 96, 96, buildZOrdering);
}

test "visual - text rendering" {
    try runVisualTest("text_rendering", 120, 60, buildTextRendering);
}
