const std = @import("std");

const forbear = @import("root.zig");
const Font = @import("font.zig");
const Graphics = @import("graphics.zig");

const Vec4 = @Vector(4, f32);
const Vec2 = @Vector(2, f32);

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

pub const Shadow = struct {
    offsetBlock: Vec2,
    offsetInline: Vec2,
    blurRadius: f32,
    spread: f32,
    color: Vec4,
};

pub const Alignment = enum {
    start,
    center,
    end,
};

pub const Style = struct {
    background: Background,
    color: Vec4,
    borderRadius: f32,
    borderColor: Vec4,
    borderBlockWidth: Vec2,
    borderInlineWidth: Vec2,

    shadow: ?Shadow = null,

    font: Font,
    fontSize: u32,
    lineHeight: f32,

    minWidth: ?f32 = null,
    preferredWidth: Sizing,
    minHeight: ?f32 = null,
    preferredHeight: Sizing,

    translate: Vec2,

    paddingInline: Vec2,
    paddingBlock: Vec2,
    marginInline: Vec2,
    marginBlock: Vec2,

    direction: Direction,
    horizontalAlignment: Alignment,
    verticalAlignment: Alignment,

    pub fn getPreferredSize(self: @This(), direction: Direction) Sizing {
        if (direction == .leftToRight) {
            return self.preferredWidth;
        }
        return self.preferredHeight;
    }
};

pub const BaseStyle = struct {
    font: Font,
    color: Vec4,
    fontSize: u32,
    lineHeight: f32,

    pub fn from(style: Style) @This() {
        return @This(){
            .font = style.font,
            .color = style.color,
            .fontSize = style.fontSize,
            .lineHeight = style.lineHeight,
        };
    }
};

pub const Background = union(enum) {
    image: *const Graphics.Image,
    color: Vec4,
};

pub const IncompleteStyle = struct {
    background: ?Background = null,
    color: ?Vec4 = null,
    borderRadius: ?f32 = null,
    borderColor: ?Vec4 = null,
    borderBlockWidth: ?Vec2 = null,
    borderInlineWidth: ?Vec2 = null,

    shadow: ?Shadow = null,

    font: ?Font = null,
    fontSize: ?u32 = null,
    lineHeight: ?f32 = null,

    minWidth: ?f32 = null,
    preferredWidth: ?Sizing = null,
    minHeight: ?f32 = null,
    preferredHeight: ?Sizing = null,

    translate: ?Vec2 = null,

    paddingInline: ?Vec2 = null,
    paddingBlock: ?Vec2 = null,
    marginInline: ?Vec2 = null,
    marginBlock: ?Vec2 = null,

    horizontalAlignment: ?Alignment = null,
    verticalAlignment: ?Alignment = null,
    direction: ?Direction = null,

    pub fn completeWith(self: @This(), base: BaseStyle) Style {
        return Style{
            .background = self.background orelse .{ .color = Vec4{ 0.0, 0.0, 0.0, 0.0 } },
            .color = self.color orelse base.color,

            .borderRadius = self.borderRadius orelse 0.0,
            .borderColor = self.borderColor orelse Vec4{ 0.0, 0.0, 0.0, 0.0 },
            .borderBlockWidth = self.borderBlockWidth orelse @splat(0.0),
            .borderInlineWidth = self.borderInlineWidth orelse @splat(0.0),

            .shadow = self.shadow,

            .font = self.font orelse base.font,
            .fontSize = self.fontSize orelse base.fontSize,
            .lineHeight = self.lineHeight orelse base.lineHeight,

            .minWidth = self.minWidth,
            .preferredWidth = self.preferredWidth orelse .fit,

            .minHeight = self.minHeight,
            .preferredHeight = self.preferredHeight orelse .fit,

            .translate = self.translate orelse @splat(0.0),

            .paddingInline = self.paddingInline orelse @splat(0.0),
            .paddingBlock = self.paddingBlock orelse @splat(0.0),
            .marginInline = self.marginInline orelse @splat(0.0),
            .marginBlock = self.marginBlock orelse @splat(0.0),

            .direction = self.direction orelse .leftToRight,
            .horizontalAlignment = self.horizontalAlignment orelse .start,
            .verticalAlignment = self.verticalAlignment orelse .start,
        };
    }
};

pub const Node = union(enum) {
    element: Element,
    component: Component,
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

pub const Component = struct {
    function: *const fn (props: ?*anyopaque) anyerror!Node,
    /// Integer associated with the static pointer to the component's function
    id: usize,
    props: *anyopaque,
};

pub inline fn component(comptime function: anytype, props: anytype, arena: std.mem.Allocator) !Node {
    const Function = @TypeOf(function);
    const functionTypeInfo = @typeInfo(Function);
    if (functionTypeInfo != .@"fn") {
        @compileError("expected function to be a `fn`, but found " ++ @typeName(function));
    }

    if (functionTypeInfo.@"fn".return_type) |ReturnType| {
        if (ReturnType != Node) {
            const returnTypeInfo = @typeInfo(ReturnType);
            if (returnTypeInfo != .error_union or returnTypeInfo.error_union.payload != Node) {
                @compileError(
                    "function components must return some Node, or an error union with Node, instead found " ++ @typeName(ReturnType),
                );
            }
        }
    } else {
        @compileError("function components must return some Node, or an error union with Node, instead found void");
    }

    if (functionTypeInfo.@"fn".params.len > 1) {
        @compileError(
            "function components can only have one parameter `props: struct`, found " ++ @typeName(functionTypeInfo.@"fn".params.len),
        );
    }

    const hasProps = functionTypeInfo.@"fn".params.len == 1;

    if (hasProps and functionTypeInfo.@"fn".params[0].type != @TypeOf(props)) {
        @compileError("expected props to be of type " ++ @typeName(functionTypeInfo.@"fn".params[0].type orelse void) ++ ", but found " ++ @typeName(@TypeOf(props)));
    }

    if (hasProps) {
        const ownedPropsPtr = try arena.create(@TypeOf(props));
        ownedPropsPtr.* = props;
        return Node{ .component = .{
            .function = &(struct {
                fn wrapper(ptr: ?*anyopaque) anyerror!Node {
                    const propsPtr: *@TypeOf(props) = @ptrCast(@alignCast(ptr));
                    return function(propsPtr.*);
                }
            }).wrapper,
            .id = @intFromPtr(&function),
            .props = @ptrCast(@alignCast(ownedPropsPtr)),
        } };
    } else {
        return Node{ .component = .{
            .function = &(struct {
                fn wrapper(_: ?*anyopaque) anyerror!Node {
                    return function();
                }
            }).wrapper,
            .id = @intFromPtr(&function),
            .props = @ptrCast(@alignCast(@constCast(&void{}))),
        } };
    }
}

pub const ElementEventHandlers = struct {
    // you are here: allow users to define the event data that is then
    // allocated for the frame and then can be used to call the underlying
    // function
    onMouseOver: ?struct {
        data: ?*anyopaque,
        handler: *const fn (mousePosition: Vec2, data: ?*anyopaque) anyerror!void,
    } = null,
    onMouseOut: ?struct {
        data: ?*anyopaque,
        handler: *const fn (mousePosition: Vec2, data: ?*anyopaque) anyerror!void,
    } = null,
};

pub const Element = struct {
    style: IncompleteStyle,
    handlers: ElementEventHandlers,
    children: ?[]Node,
};

pub const ElementProps = struct {
    style: IncompleteStyle = .{},
    handlers: ElementEventHandlers = .{},
    children: ?[]Node = null,
};

pub fn div(props: ElementProps) Node {
    return .{
        .element = .{
            .style = props.style,
            .handlers = props.handlers,
            .children = props.children,
        },
    };
}

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
        const valueTypeInfo = @typeInfo(Value);

        if (valueTypeInfo == .optional) {
            if (value != null) {
                try arrayList.append(allocator, try Node.from(value.?, allocator));
            }
            continue;
        }

        if (valueTypeInfo == .pointer and valueTypeInfo.pointer.size == .slice and valueTypeInfo.pointer.child == Node) {
            try arrayList.appendSlice(allocator, value);
            continue;
        }

        if (valueTypeInfo == .array and valueTypeInfo.array.child == Node) {
            try arrayList.appendSlice(allocator, &value);
            continue;
        }

        try arrayList.append(allocator, try Node.from(value, allocator));
    }

    return arrayList.items;
}
