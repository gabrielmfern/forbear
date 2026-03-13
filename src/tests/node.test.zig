const std = @import("std");

const node = @import("../node.zig");
const utilities = @import("utilities.zig");

const Alignment = node.Alignment;
const BaseStyle = node.BaseStyle;
const BorderWidth = node.BorderWidth;
const Direction = node.Direction;
const IncompleteStyle = node.IncompleteStyle;
const Margin = node.Margin;
const Node = node.Node;
const Padding = node.Padding;
const Style = node.Style;

const Vec2 = @Vector(2, f32);
const Vec4 = @Vector(4, f32);

fn makeNode(style: Style, size: Vec2, minSize: Vec2, maxSize: Vec2) Node {
    return .{
        .key = 1,
        .position = .{ 0.0, 0.0 },
        .z = 0,
        .size = size,
        .minSize = minSize,
        .maxSize = maxSize,
        .children = .{ .nodes = .empty },
        .style = style,
    };
}

test "Direction.perpendicular swaps axes" {
    try std.testing.expectEqual(Direction.topToBottom, Direction.leftToRight.perpendicular());
    try std.testing.expectEqual(Direction.leftToRight, Direction.topToBottom.perpendicular());
}

test "Style axis helpers return the requested direction values" {
    const style = Style{
        .background = .{ .color = Vec4{ 0.1, 0.2, 0.3, 1.0 } },
        .blendMode = .multiply,
        .filter = .grayscale,
        .color = Vec4{ 0.9, 0.8, 0.7, 1.0 },
        .borderRadius = 6.0,
        .borderColor = Vec4{ 0.4, 0.5, 0.6, 1.0 },
        .borderWidth = BorderWidth.block(3.0),
        .font = undefined,
        .fontWeight = 500,
        .fontSize = 18.0,
        .lineHeight = 1.2,
        .textWrapping = .character,
        .cursor = .pointer,
        .placement = .standard,
        .width = .{ .fixed = 120.0 },
        .minWidth = 80.0,
        .maxWidth = 140.0,
        .height = .grow,
        .minHeight = 40.0,
        .maxHeight = 160.0,
        .translate = .{ 1.0, 2.0 },
        .padding = Padding.inLine(4.0),
        .margin = Margin.block(5.0),
        .direction = .leftToRight,
        .alignment = Alignment.center,
    };

    try std.testing.expectEqualDeep(style.width, style.getPreferredSize(.leftToRight));
    try std.testing.expectEqualDeep(style.height, style.getPreferredSize(.topToBottom));
    try std.testing.expectEqual(@as(?f32, 80.0), style.getMinSize(.leftToRight));
    try std.testing.expectEqual(@as(?f32, 40.0), style.getMinSize(.topToBottom));
}

test "BaseStyle.from copies inheritable fields" {
    const fakeFont: @TypeOf(utilities.shallowBaseStyle.font) = @ptrFromInt(8);
    const style = Style{
        .background = .{ .color = Vec4{ 0.0, 0.0, 0.0, 0.0 } },
        .blendMode = .multiply,
        .filter = .grayscale,
        .color = Vec4{ 0.2, 0.3, 0.4, 1.0 },
        .borderRadius = 9.0,
        .borderColor = Vec4{ 0.5, 0.6, 0.7, 1.0 },
        .borderWidth = BorderWidth.all(2.0),
        .font = fakeFont,
        .fontWeight = 650,
        .fontSize = 22.0,
        .lineHeight = 1.4,
        .textWrapping = .word,
        .cursor = .text,
        .placement = .standard,
        .width = .grow,
        .height = .fit,
        .translate = .{ 3.0, 4.0 },
        .padding = Padding.all(5.0),
        .margin = Margin.all(6.0),
        .direction = .topToBottom,
        .alignment = Alignment.bottomRight,
    };

    const base = BaseStyle.from(style);
    try std.testing.expect(base.font == style.font);
    try std.testing.expectEqualDeep(style.color, base.color);
    try std.testing.expectEqual(style.fontSize, base.fontSize);
    try std.testing.expectEqual(style.fontWeight, base.fontWeight);
    try std.testing.expectEqual(style.lineHeight, base.lineHeight);
    try std.testing.expectEqual(style.textWrapping, base.textWrapping);
    try std.testing.expectEqual(style.blendMode, base.blendMode);
    try std.testing.expectEqual(style.filter, base.filter);
    try std.testing.expectEqual(style.cursor, base.cursor);
}

test "IncompleteStyle.completeWith uses base inheritance and built in defaults" {
    const fakeFont: @TypeOf(utilities.shallowBaseStyle.font) = @ptrFromInt(8);
    const base = BaseStyle{
        .font = fakeFont,
        .color = Vec4{ 0.7, 0.6, 0.5, 1.0 },
        .fontSize = 17.0,
        .fontWeight = 550,
        .lineHeight = 1.3,
        .textWrapping = .word,
        .blendMode = .multiply,
        .filter = .grayscale,
        .cursor = .pointer,
    };

    const resolved = (IncompleteStyle{}).completeWith(base);
    switch (resolved.background) {
        .color => |color| try std.testing.expectEqualDeep(Vec4{ 0.0, 0.0, 0.0, 0.0 }, color),
        else => return error.ExpectedColorBackground,
    }
    try std.testing.expectEqual(base.blendMode, resolved.blendMode);
    try std.testing.expectEqual(base.filter, resolved.filter);
    try std.testing.expectEqualDeep(base.color, resolved.color);
    try std.testing.expectEqual(@as(f32, 0.0), resolved.borderRadius);
    try std.testing.expectEqualDeep(Vec4{ 0.0, 0.0, 0.0, 0.0 }, resolved.borderColor);
    try std.testing.expectEqualDeep(BorderWidth.all(0.0), resolved.borderWidth);
    try std.testing.expect(resolved.shadow == null);
    try std.testing.expect(resolved.font == base.font);
    try std.testing.expectEqual(base.fontWeight, resolved.fontWeight);
    try std.testing.expectEqual(base.fontSize, resolved.fontSize);
    try std.testing.expectEqual(base.lineHeight, resolved.lineHeight);
    try std.testing.expectEqual(base.textWrapping, resolved.textWrapping);
    try std.testing.expectEqual(base.cursor, resolved.cursor);
    try std.testing.expectEqual(@as(?f32, null), resolved.minWidth);
    try std.testing.expectEqual(@as(?f32, null), resolved.maxWidth);
    try std.testing.expectEqualDeep(node.Sizing.fit, resolved.width);
    try std.testing.expectEqual(@as(?f32, null), resolved.minHeight);
    try std.testing.expectEqual(@as(?f32, null), resolved.maxHeight);
    try std.testing.expectEqualDeep(node.Sizing.fit, resolved.height);
    try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, resolved.translate);
    try std.testing.expectEqualDeep(Padding.all(0.0), resolved.padding);
    try std.testing.expectEqualDeep(Margin.all(0.0), resolved.margin);
    try std.testing.expectEqual(Direction.leftToRight, resolved.direction);
    try std.testing.expectEqualDeep(Alignment.topLeft, resolved.alignment);
}

test "IncompleteStyle.completeWith lets explicit overrides win selectively" {
    const fakeFont: @TypeOf(utilities.shallowBaseStyle.font) = @ptrFromInt(8);
    var base = utilities.shallowBaseStyle;
    base.font = fakeFont;
    const shadow = node.Shadow{
        .offset = Padding.left(3.0),
        .blurRadius = 5.0,
        .spread = 2.0,
        .color = Vec4{ 0.1, 0.2, 0.3, 0.4 },
    };
    const resolved = (IncompleteStyle{
        .background = .{ .color = Vec4{ 0.9, 0.8, 0.7, 1.0 } },
        .blendMode = .multiply,
        .filter = .grayscale,
        .color = Vec4{ 0.6, 0.5, 0.4, 1.0 },
        .borderRadius = 12.0,
        .borderColor = Vec4{ 0.2, 0.3, 0.4, 1.0 },
        .borderWidth = BorderWidth.right(6.0),
        .shadow = shadow,
        .fontWeight = 700,
        .fontSize = 24.0,
        .lineHeight = 1.6,
        .textWrapping = .character,
        .cursor = .pointer,
        .placement = .{ .manual = .{ 9.0, 10.0 } },
        .zIndex = 8,
        .minWidth = 20.0,
        .maxWidth = 200.0,
        .width = .grow,
        .minHeight = 30.0,
        .maxHeight = 300.0,
        .height = .{ .fixed = 70.0 },
        .translate = .{ 11.0, 12.0 },
        .padding = Padding.top(4.0),
        .margin = Margin.bottom(5.0),
        .alignment = Alignment.bottomCenter,
        .direction = .topToBottom,
    }).completeWith(base);

    switch (resolved.background) {
        .color => |color| try std.testing.expectEqualDeep(Vec4{ 0.9, 0.8, 0.7, 1.0 }, color),
        else => return error.ExpectedColorBackground,
    }
    try std.testing.expectEqual(.multiply, resolved.blendMode);
    try std.testing.expectEqual(.grayscale, resolved.filter);
    try std.testing.expectEqualDeep(Vec4{ 0.6, 0.5, 0.4, 1.0 }, resolved.color);
    try std.testing.expectEqual(@as(f32, 12.0), resolved.borderRadius);
    try std.testing.expectEqualDeep(Vec4{ 0.2, 0.3, 0.4, 1.0 }, resolved.borderColor);
    try std.testing.expectEqualDeep(BorderWidth.right(6.0), resolved.borderWidth);
    try std.testing.expectEqualDeep(shadow, resolved.shadow.?);
    try std.testing.expect(resolved.font == base.font);
    try std.testing.expectEqual(@as(u32, 700), resolved.fontWeight);
    try std.testing.expectEqual(@as(f32, 24.0), resolved.fontSize);
    try std.testing.expectEqual(@as(f32, 1.6), resolved.lineHeight);
    try std.testing.expectEqual(node.TextWrapping.character, resolved.textWrapping);
    try std.testing.expectEqual(.pointer, resolved.cursor);
    try std.testing.expectEqualDeep(node.Placement{ .manual = .{ 9.0, 10.0 } }, resolved.placement);
    try std.testing.expectEqual(@as(?u16, 8), resolved.zIndex);
    try std.testing.expectEqual(@as(?f32, 20.0), resolved.minWidth);
    try std.testing.expectEqual(@as(?f32, 200.0), resolved.maxWidth);
    try std.testing.expectEqualDeep(node.Sizing.grow, resolved.width);
    try std.testing.expectEqual(@as(?f32, 30.0), resolved.minHeight);
    try std.testing.expectEqual(@as(?f32, 300.0), resolved.maxHeight);
    try std.testing.expectEqualDeep(node.Sizing{ .fixed = 70.0 }, resolved.height);
    try std.testing.expectEqualDeep(Vec2{ 11.0, 12.0 }, resolved.translate);
    try std.testing.expectEqualDeep(Padding.top(4.0), resolved.padding);
    try std.testing.expectEqualDeep(Margin.bottom(5.0), resolved.margin);
    try std.testing.expectEqualDeep(Alignment.bottomCenter, resolved.alignment);
    try std.testing.expectEqual(Direction.topToBottom, resolved.direction);
}

test "Node helpers cover fit logic ratios and axis setters" {
    var fitHorizontal = makeNode((IncompleteStyle{
        .direction = .leftToRight,
        .width = .fit,
        .height = .fit,
        .padding = Padding.inLine(2.0),
        .borderWidth = BorderWidth.inLine(1.0),
    }).completeWith(utilities.shallowBaseStyle), .{ 6.0, 4.0 }, .{ 6.0, 4.0 }, .{ 100.0, 100.0 });
    const childHorizontal = makeNode((IncompleteStyle{
        .width = .{ .fixed = 20.0 },
        .height = .{ .fixed = 10.0 },
        .margin = Margin{
            .x = .{ 3.0, 4.0 },
            .y = .{ 5.0, 6.0 },
        },
    }).completeWith(utilities.shallowBaseStyle), .{ 20.0, 10.0 }, .{ 20.0, 10.0 }, .{ 20.0, 10.0 });
    fitHorizontal.fitChild(&childHorizontal);
    try std.testing.expectEqual(@as(f32, 33.0), fitHorizontal.size[0]);
    try std.testing.expectEqual(@as(f32, 21.0), fitHorizontal.size[1]);
    try std.testing.expectEqual(@as(f32, 33.0), fitHorizontal.minSize[0]);
    try std.testing.expectEqual(@as(f32, 21.0), fitHorizontal.minSize[1]);
    try std.testing.expectEqual(@as(f32, 6.0), fitHorizontal.fittingBase(.leftToRight));
    try std.testing.expectEqual(@as(f32, 0.0), fitHorizontal.fittingBase(.topToBottom));
    try std.testing.expect(fitHorizontal.shouldFitMin(.leftToRight));

    var fitVertical = makeNode((IncompleteStyle{
        .direction = .topToBottom,
        .width = .fit,
        .height = .fit,
        .padding = Padding.block(2.0),
        .borderWidth = BorderWidth.block(1.0),
    }).completeWith(utilities.shallowBaseStyle), .{ 4.0, 6.0 }, .{ 4.0, 6.0 }, .{ 100.0, 100.0 });
    const childVertical = makeNode((IncompleteStyle{
        .width = .{ .fixed = 30.0 },
        .height = .{ .fixed = 15.0 },
        .margin = Margin{
            .x = .{ 2.0, 3.0 },
            .y = .{ 4.0, 5.0 },
        },
    }).completeWith(utilities.shallowBaseStyle), .{ 30.0, 15.0 }, .{ 30.0, 15.0 }, .{ 30.0, 15.0 });
    fitVertical.fitChild(&childVertical);
    try std.testing.expectEqual(@as(f32, 30.0), fitVertical.size[1]);
    try std.testing.expectEqual(@as(f32, 35.0), fitVertical.size[0]);
    try std.testing.expectEqual(@as(f32, 30.0), fitVertical.minSize[1]);
    try std.testing.expectEqual(@as(f32, 35.0), fitVertical.minSize[0]);
    try std.testing.expectEqual(@as(f32, 6.0), fitVertical.fittingBase(.topToBottom));
    try std.testing.expectEqual(@as(f32, 0.0), fitVertical.fittingBase(.leftToRight));
    try std.testing.expect(fitVertical.shouldFitMin(.topToBottom));

    var widthRatio = makeNode((IncompleteStyle{
        .width = .{ .ratio = 2.0 },
        .height = .{ .fixed = 15.0 },
    }).completeWith(utilities.shallowBaseStyle), .{ 0.0, 15.0 }, .{ 0.0, 15.0 }, .{ 100.0, 100.0 });
    widthRatio.applyRatios();
    try std.testing.expectEqual(@as(f32, 30.0), widthRatio.size[0]);

    var heightRatio = makeNode((IncompleteStyle{
        .width = .{ .fixed = 12.0 },
        .height = .{ .ratio = 3.0 },
    }).completeWith(utilities.shallowBaseStyle), .{ 12.0, 0.0 }, .{ 12.0, 0.0 }, .{ 100.0, 100.0 });
    heightRatio.applyRatios();
    try std.testing.expectEqual(@as(f32, 36.0), heightRatio.size[1]);

    var setters = makeNode((IncompleteStyle{
        .width = .grow,
        .height = .grow,
    }).completeWith(utilities.shallowBaseStyle), .{ 1.0, 2.0 }, .{ 3.0, 4.0 }, .{ 50.0, 60.0 });
    setters.setSize(.leftToRight, 10.0);
    setters.setSize(.topToBottom, 20.0);
    setters.addSize(.leftToRight, 5.0);
    setters.addSize(.topToBottom, 6.0);
    setters.setMinSize(.leftToRight, 7.0);
    setters.setMinSize(.topToBottom, 8.0);
    setters.addMinSize(.leftToRight, 1.0);
    setters.addMinSize(.topToBottom, 2.0);
    try std.testing.expectEqual(@as(f32, 15.0), setters.getSize(.leftToRight));
    try std.testing.expectEqual(@as(f32, 26.0), setters.getSize(.topToBottom));
    try std.testing.expectEqual(@as(f32, 8.0), setters.getMinSize(.leftToRight));
    try std.testing.expectEqual(@as(f32, 10.0), setters.getMinSize(.topToBottom));
    try std.testing.expectEqual(@as(f32, 50.0), setters.getMaxSize(.leftToRight));
    try std.testing.expectEqual(@as(f32, 60.0), setters.getMaxSize(.topToBottom));

    const fixedWidth = makeNode((IncompleteStyle{
        .width = .{ .fixed = 10.0 },
        .height = .grow,
    }).completeWith(utilities.shallowBaseStyle), .{ 10.0, 10.0 }, .{ 10.0, 0.0 }, .{ 10.0, 100.0 });
    try std.testing.expect(!fixedWidth.shouldFitMin(.leftToRight));

    const percentageHeight = makeNode((IncompleteStyle{
        .width = .grow,
        .height = .{ .percentage = 0.5 },
    }).completeWith(utilities.shallowBaseStyle), .{ 10.0, 10.0 }, .{ 0.0, 0.0 }, .{ 100.0, 100.0 });
    try std.testing.expect(!percentageHeight.shouldFitMin(.topToBottom));
}
