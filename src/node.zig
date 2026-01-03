const std = @import("std");
const Font = @import("text.zig").Font;
const Vec4 = @Vector(4, f32);

pub const Direction = enum {
    leftToRight,
    topToBottom,

    pub fn perpendicular(self: @This()) @This() {
        return switch (self) {
            .leftToRight => .topToBottom,
            .topToBottom => .leftToRight,
        };
    }
};

pub const Sizing = union(enum) {
    fit,
    fixed: f32,
    grow,
};

pub const Style = struct {
    backgroundColor: Vec4,
    borderRadius: f32,

    font: Font,
    fontSize: u32,
    lineHeight: f32,

    minWidth: ?f32 = null,
    preferredWidth: Sizing,
    minHeight: ?f32 = null,
    preferredHeight: Sizing,

    paddingLeft: f32,
    paddingRight: f32,
    paddingTop: f32,
    paddingBottom: f32,

    direction: Direction,

    pub fn getPreferredSize(self: @This(), direction: Direction) Sizing {
        if (direction == .leftToRight) {
            return self.preferredWidth;
        }
        return self.preferredHeight;
    }
};

pub const BaseStyle = struct {
    font: Font,
    fontSize: u32,
    lineHeight: f32,

    pub fn from(style: Style) @This() {
        return @This(){
            .font = style.font,
            .fontSize = style.fontSize,
            .lineHeight = style.lineHeight,
        };
    }
};

pub const IncompleteStyle = struct {
    backgroundColor: ?Vec4 = null,
    borderRadius: ?f32 = null,

    font: ?Font = null,
    fontSize: ?u32 = null,
    lineHeight: ?f32 = null,

    minWidth: ?f32 = null,
    preferredWidth: ?Sizing = null,
    minHeight: ?f32 = null,
    preferredHeight: ?Sizing = null,

    paddingLeft: ?f32 = null,
    paddingRight: ?f32 = null,
    paddingTop: ?f32 = null,
    paddingBottom: ?f32 = null,

    direction: ?Direction = null,

    pub fn completeWith(self: @This(), base: BaseStyle) Style {
        return Style{
            .backgroundColor = self.backgroundColor orelse Vec4{ 0.0, 0.0, 0.0, 0.0 },
            .borderRadius = self.borderRadius orelse 0.0,

            .font = self.font orelse base.font,
            .fontSize = self.fontSize orelse base.fontSize,
            .lineHeight = self.lineHeight orelse base.lineHeight,

            .minWidth = self.minWidth,
            .preferredWidth = self.preferredWidth orelse .fit,

            .minHeight = self.minHeight,
            .preferredHeight = self.preferredHeight orelse .fit,

            .paddingLeft = self.paddingLeft orelse 0.0,
            .paddingRight = self.paddingRight orelse 0.0,
            .paddingTop = self.paddingTop orelse 0.0,
            .paddingBottom = self.paddingBottom orelse 0.0,

            .direction = self.direction orelse .leftToRight,
        };
    }
};

pub const Node = union(enum) {
    element: Element,
    text: []const u8,

    pub fn from(value: anytype, allocator: std.mem.Allocator) !Node {
        const Value = @TypeOf(value);
        const valueTypeInfo = @typeInfo(Value);

        if (Value == Node) {
            return value;
        }

        if (valueTypeInfo == .pointer and valueTypeInfo.pointer.size == .slice and valueTypeInfo.pointer.child == u8) {
            return Node{
                .text = value,
            };
        }

        if (valueTypeInfo == .int or valueTypeInfo == .float) {
            const stringified = try std.fmt.allocPrint(allocator, "{d:.1}", .{value});
            return Node{
                .text = stringified,
            };
        }

        if (valueTypeInfo == .bool) {
            return Node{
                .text = if (value) "true" else "false",
            };
        }

        if (valueTypeInfo == .pointer) {
            const child_type_info = @typeInfo(valueTypeInfo.pointer.child);

            if (child_type_info == .array and child_type_info.array.child == u8) {
                return Node{
                    .text = value,
                };
            }

            return Node.from(value.*, allocator);
        }

        if (valueTypeInfo == .error_union) {
            return Node.from(try value, allocator);
        }

        @compileError("The type " ++ @typeName(Value) ++ " cannot be converted into a Node for rendering");
    }
};

pub const Element = struct {
    style: IncompleteStyle,
    children: ?[]Node,
};

pub const ElementProps = struct {
    style: IncompleteStyle = .{},
    children: ?[]Node = null,
};

pub fn children(args: anytype, allocator: std.mem.Allocator) !?[]Node {
    const ArgsType = @TypeOf(args);
    const typeInfo = @typeInfo(ArgsType);
    if (typeInfo == .null) {
        return null;
    }
    if (typeInfo != .@"struct") {
        @compileError("Expected a struct, found " ++ @typeName(ArgsType));
    }

    var arrayList = try std.ArrayList(Node).initCapacity(allocator, args.len);

    inline for (args) |value| {
        const Value = @TypeOf(value);
        const value_type_info = @typeInfo(Value);

        if (value_type_info == .pointer and value_type_info.pointer.size == .slice and value_type_info.pointer.child == Node) {
            try arrayList.appendSlice(allocator, value);
            continue;
        }

        if (value_type_info == .array and value_type_info.array.child == Node) {
            try arrayList.appendSlice(allocator, &value);
            continue;
        }

        try arrayList.append(allocator, try Node.from(value, allocator));
    }

    return arrayList.items;
}

pub fn div(props: ElementProps) Node {
    return .{
        .element = .{
            .style = props.style,
            .children = props.children,
        },
    };
}
