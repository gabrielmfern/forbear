const std = @import("std");
const builtin = @import("builtin");

pub const c = @import("c.zig").c;
pub const Font = @import("font.zig");
pub const Graphics = @import("graphics.zig");
pub const Image = @import("graphics.zig").Image;
const layouting = @import("layouting.zig");
pub const layout = layouting.layout;
pub const LayoutBox = layouting.LayoutBox;
const nodeImport = @import("node.zig");
pub const Node = nodeImport.Node;
pub const Component = nodeImport.Component;
pub const component = nodeImport.component;
pub const ComponentProps = nodeImport.ComponentProps;
pub const Element = nodeImport.Element;
pub const ElementProps = nodeImport.DivProps;
pub const div = nodeImport.div;
pub const children = nodeImport.children;
pub const Window = @import("window/root.zig").Window;

const Vec2 = @Vector(2, f32);

const Context = @This();

var context: ?@This() = null;

allocator: std.mem.Allocator,
mousePosition: Vec2,
hoveredElementKey: ?u64,

// TODO: The alignment here is probably messed up, we should find a way to fix
// it later
/// A literal string of bytes that have the size of some state, and the
componentStates: std.AutoHashMap(u64, []align(@alignOf(usize)) u8),
componentResolutionState: ?ComponentResolutionState,

const ComponentResolutionState = struct {
    arenaAllocator: std.mem.Allocator,
    stateByteCursor: usize,
    key: u64,
};

pub fn init(allocator: std.mem.Allocator) !void {
    if (context != null) {
        return error.AlreadyInitialized;
    }

    context = @This(){
        .mousePosition = .{ 0.0, 0.0 },
        .hoveredElementKey = null,
        .allocator = allocator,
        .componentStates = .init(allocator),
        .componentResolutionState = null,
    };
}

/// TODO: inherit all properties from Node, and add the key and differnet
/// children, as well as removing the component variant
pub const TreeNode = struct {
    key: u64,
    node: Node,
    children: ?[]TreeNode,
};

const Resolver = struct {
    path: std.ArrayList(usize),
    arenaAllocator: std.mem.Allocator,

    fn init(arenaAllocator: std.mem.Allocator) !@This() {
        return .{
            .arenaAllocator = arenaAllocator,
            .path = try std.ArrayList(usize).initCapacity(arenaAllocator, 0),
        };
    }

    fn resolve(self: *@This(), node: Node) !TreeNode {
        const forbear = getContext();

        var hasher = std.hash.Wyhash.init(0);
        hasher.update(std.mem.sliceAsBytes(self.path.items));
        switch (node) {
            .component => |comp| {
                hasher.update(std.mem.asBytes(&comp.id));
                const key = hasher.final();

                // TODO(up next): find a way to free the state data once the component instance is gone
                const previousComponentResolutionState = forbear.componentResolutionState;
                forbear.componentResolutionState = .{
                    .key = key,
                    .arenaAllocator = self.arenaAllocator,
                    .stateByteCursor = 0,
                };
                const componentNode = try comp.function(comp.props);
                if (!forbear.componentStates.contains(key) or forbear.componentResolutionState.?.stateByteCursor != forbear.componentStates.get(key).?.len) {
                    return error.RulesOfHooksViolated;
                }
                forbear.componentResolutionState = previousComponentResolutionState;
                // TODO: investigate if should we reuse the same key as above?
                // Is it a problem that it creates a new key here?
                return self.resolve(componentNode);
            },
            .element => {
                if (node.element.children != null) {
                    var treeChildren = try self.arenaAllocator.alloc(TreeNode, node.element.children.?.len);
                    for (node.element.children.?, 0..) |child, i| {
                        try self.path.append(self.arenaAllocator, i);
                        defer _ = self.path.pop();
                        treeChildren[i] = try self.resolve(child);
                    }
                    return .{
                        .key = hasher.final(),
                        .node = node,
                        .children = treeChildren,
                    };
                } else {
                    return .{
                        .key = hasher.final(),
                        .node = node,
                        .children = null,
                    };
                }
            },
            .text => |text| {
                hasher.update(text);
                return .{
                    .key = hasher.final(),
                    .node = node,
                    .children = null,
                };
            },
        }
    }
};

pub fn resolve(rootNode: Node, arenaAllocator: std.mem.Allocator) !TreeNode {
    var resolver = try Resolver.init(arenaAllocator);

    return resolver.resolve(rootNode);
}

test "Component resolution" {
    try init(std.testing.allocator);
    defer deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var callCount: u32 = 0;

    const MyComponentProps = struct {
        callCount: *u32,
        value: u32,
        arenaAllocator: std.mem.Allocator,
    };

    const MyComponent = (struct {
        fn component(props: MyComponentProps) !Node {
            props.callCount.* += 1;
            const counter = try useState(u32, props.value);
            try std.testing.expectEqual(props.value, counter.*);
            return div(.{
                .children = try children(.{ "Value: ", counter.* }, props.arenaAllocator),
            });
        }
    }).component;

    const rootNode = div(.{
        .children = try children(.{
            try component(
                MyComponent,
                MyComponentProps{ .callCount = &callCount, .value = 10, .arenaAllocator = arenaAllocator },
                arenaAllocator,
            ),
            try component(
                MyComponent,
                MyComponentProps{ .callCount = &callCount, .value = 20, .arenaAllocator = arenaAllocator },
                arenaAllocator,
            ),
        }, arenaAllocator),
    });

    _ = try resolve(rootNode, arenaAllocator);
    try std.testing.expectEqual(2, callCount);

    _ = try resolve(rootNode, arenaAllocator);
    try std.testing.expectEqual(4, callCount);
}

const stateAlignment: std.mem.Alignment = .@"8";

pub fn useArena() !std.mem.Allocator {
    const self = getContext();
    if (self.componentResolutionState) |state| {
        return state.arenaAllocator;
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling a hook (useArena) outside of a component, and forbear cannot track things outside of one.", .{});
        }
        return error.NoComponentContext;
    }
}

// TODO: in debug mode, we should be adding some guard rail here to make sure
// of warning the user if they called the hook in an unexpected order, as it
// can cause undefined behavior as is right now
pub fn useState(T: type, initialValue: T) !*T {
    const self = getContext();
    if (self.componentResolutionState) |*state| {
        const stateResult = try self.componentStates.getOrPut(state.key);
        const alignedCursor = std.mem.alignForward(usize, state.stateByteCursor, @alignOf(T));
        const requiredLen = alignedCursor + @sizeOf(T);
        defer state.stateByteCursor = requiredLen;
        if (stateResult.found_existing) {
            if (alignedCursor < stateResult.value_ptr.*.len) {
                return @ptrCast(@alignCast(stateResult.value_ptr.*[alignedCursor..requiredLen]));
            }
            stateResult.value_ptr.* = try self.allocator.realloc(stateResult.value_ptr.*, requiredLen);
        } else {
            stateResult.value_ptr.* = try self.allocator.alignedAlloc(u8, stateAlignment, requiredLen);
        }
        @memcpy(
            stateResult.value_ptr.*[alignedCursor..requiredLen],
            std.mem.asBytes(&initialValue),
        );
        return @ptrCast(@alignCast(stateResult.value_ptr.*[alignedCursor..requiredLen]));
    } else {
        if (!builtin.is_test) {
            std.log.err("You might be calling a hook (useState) outside of a component, and forbear cannot track things outside of one.", .{});
        }
        return error.NoComponentContext;
    }
}

test "State creation with manual handling" {
    try init(std.testing.allocator);
    defer deinit();
    const self = getContext();
    {
        // First run that should allocate RAM, and still allow reading and writing the values
        self.componentResolutionState = ComponentResolutionState{
            .stateByteCursor = 0,
            .key = 1,
            .arenaAllocator = std.testing.allocator,
        };
        const state1 = try useState(i32, 42);
        try std.testing.expectEqual(@sizeOf(i32), self.componentStates.get(1).?.len);
        const state2 = try useState(f32, 3.14);
        try std.testing.expectEqual(@sizeOf(i32) + @sizeOf(f32), self.componentStates.get(1).?.len);
        try std.testing.expectEqual(42, state1.*);
        try std.testing.expectEqual(3.14, state2.*);
        state1.* = 100;
        state2.* = 6.28;
        try std.testing.expectEqual(100, state1.*);
        try std.testing.expectEqual(6.28, state2.*);
    }
    {
        // Second run that should not allcoate new memory
        self.componentResolutionState = ComponentResolutionState{
            .stateByteCursor = 0,
            .key = 1,
            .arenaAllocator = std.testing.allocator,
        };
        const state1 = try useState(i32, 42);
        try std.testing.expectEqual(@sizeOf(i32) + @sizeOf(f32), self.componentStates.get(1).?.len);
        const state2 = try useState(f32, 3.14);
        try std.testing.expectEqual(@sizeOf(i32) + @sizeOf(f32), self.componentStates.get(1).?.len);
        try std.testing.expectEqual(100, state1.*);
        try std.testing.expectEqual(6.28, state2.*);
    }
    {
        self.componentResolutionState = null;
        try std.testing.expectError(error.NoComponentContext, useState(i32, 42));
    }
}

pub fn update(root: *const LayoutBox, arena: std.mem.Allocator) !void {
    const self = getContext();

    var iterator = try layouting.LayoutTreeIterator.init(arena, root);
    var previouslyHoveredLayoutBox: ?*const LayoutBox = null;

    var highestHoveredLayoutBox: ?*const LayoutBox = null;
    while (try iterator.next()) |layoutBox| {
        if (layoutBox.position[0] <= self.mousePosition[0] and layoutBox.position[1] <= self.mousePosition[1] and layoutBox.position[0] + layoutBox.size[0] >= self.mousePosition[0] and layoutBox.position[1] + layoutBox.size[1] >= self.mousePosition[1]) {
            if (highestHoveredLayoutBox) |hoveredBox| {
                if (layoutBox.z > hoveredBox.z) {
                    highestHoveredLayoutBox = layoutBox;
                }
            } else {
                highestHoveredLayoutBox = layoutBox;
            }
        }
        if (layoutBox.key == self.hoveredElementKey) {
            previouslyHoveredLayoutBox = layoutBox;
        }
    }
    if (highestHoveredLayoutBox) |hoveredBox| {
        if (hoveredBox.key != self.hoveredElementKey) {
            if (previouslyHoveredLayoutBox) |prevBox| {
                if (prevBox.handlers.onMouseOut) |onMouseOut| {
                    try onMouseOut.handler(self.mousePosition, onMouseOut.data);
                }
            }
        }
        if (hoveredBox.handlers.onMouseOver) |onMouseOver| {
            try onMouseOver.handler(self.mousePosition, onMouseOver.data);
            self.hoveredElementKey = hoveredBox.key;
        }
    } else if (previouslyHoveredLayoutBox) |prevBox| {
        if (prevBox.handlers.onMouseOut) |onMouseOut| {
            try onMouseOut.handler(self.mousePosition, onMouseOut.data);
            self.hoveredElementKey = null;
        }
    }
}

pub fn setHandlers(window: *Window) void {
    const self = getContext();

    window.setPointerMotion(
        &(struct {
            fn handler(_: *Window, time: u32, x: i32, y: i32, data: *anyopaque) void {
                _ = time;
                const ctx: *Context = @ptrCast(@alignCast(data));
                ctx.mousePosition = .{ @floatFromInt(x), @floatFromInt(y) };
            }
        }).handler,
        @ptrCast(@alignCast(self)),
    );
}

pub fn deinit() void {
    const self = getContext();
    std.debug.assert(self.componentResolutionState == null);
    var nodeStatesIterator = self.componentStates.valueIterator();
    while (nodeStatesIterator.next()) |states| {
        self.allocator.free(states.*);
    }
    self.componentStates.deinit();
    context = null;
}

pub fn getContext() *@This() {
    return &context.?;
}
