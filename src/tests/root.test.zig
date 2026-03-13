const std = @import("std");
const forbear = @import("../root.zig");
const Sizing = @import("../node.zig").Sizing;
const utilities = @import("utilities.zig");
const Vec2 = @Vector(2, f32);

test "Element tree stack stability" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            const nodeParentStack = &self.frameMeta.?.nodeParentStack;
            const nodePath = &self.frameMeta.?.nodePath;
            try std.testing.expectEqual(1, nodeParentStack.items.len);
            try std.testing.expectEqual(1, nodePath.items.len);
            try forbear.FpsCounter();

            try std.testing.expectEqual(1, nodeParentStack.items.len);
            try std.testing.expectEqual(1, nodePath.items.len);
            forbear.element(.{})({
                try std.testing.expectEqual(2, nodeParentStack.items.len);
                try std.testing.expectEqual(2, nodePath.items.len);

                forbear.text("Hello, world!");
                try std.testing.expectEqual(2, nodeParentStack.items.len);
                try std.testing.expectEqual(2, nodePath.items.len);

                forbear.element(.{})({
                    try std.testing.expectEqual(3, nodeParentStack.items.len);
                    try std.testing.expectEqual(3, nodePath.items.len);

                    forbear.text("Nested element");
                    try std.testing.expectEqual(3, nodeParentStack.items.len);
                    try std.testing.expectEqual(3, nodePath.items.len);
                });

                try std.testing.expectEqual(2, nodeParentStack.items.len);
                try std.testing.expectEqual(2, nodePath.items.len);
            });
            try std.testing.expectEqual(1, nodeParentStack.items.len);
        });
        try std.testing.expectEqual(0, self.frameMeta.?.nodeParentStack.items.len);
        try std.testing.expectEqual(0, self.frameMeta.?.nodePath.items.len);
        try std.testing.expect(self.frameMeta.?.rootNode != null);
    });

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            const nodeParentStack = &self.frameMeta.?.nodeParentStack;
            const nodePath = &self.frameMeta.?.nodePath;
            try std.testing.expectEqual(1, nodeParentStack.items.len);
            try std.testing.expectEqual(1, nodePath.items.len);
            try forbear.FpsCounter();
            try std.testing.expectEqual(1, nodeParentStack.items.len);
            try std.testing.expectEqual(1, nodePath.items.len);
            forbear.element(.{})({
                try std.testing.expectEqual(2, nodeParentStack.items.len);
                try std.testing.expectEqual(2, nodePath.items.len);

                forbear.text("Hello, world!");
                try std.testing.expectEqual(2, nodeParentStack.items.len);
                try std.testing.expectEqual(2, nodePath.items.len);

                forbear.element(.{})({
                    try std.testing.expectEqual(3, nodeParentStack.items.len);
                    try std.testing.expectEqual(3, nodePath.items.len);

                    forbear.text("Nested element");
                    try std.testing.expectEqual(3, nodeParentStack.items.len);
                    try std.testing.expectEqual(3, nodePath.items.len);
                });

                try std.testing.expectEqual(2, nodeParentStack.items.len);
                try std.testing.expectEqual(2, nodePath.items.len);
            });
            try std.testing.expectEqual(1, nodeParentStack.items.len);
        });
        try std.testing.expectEqual(0, self.frameMeta.?.nodeParentStack.items.len);
        try std.testing.expectEqual(0, self.frameMeta.?.nodePath.items.len);
        try std.testing.expect(self.frameMeta.?.rootNode != null);
    });
}

test "Element key stability across frames" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    // Helper to collect keys from the tree
    const collectKeys = struct {
        fn collect(
            allocator: std.mem.Allocator,
            node: *const forbear.Node,
            arrayList: *std.ArrayList(u64),
        ) !void {
            try arrayList.append(allocator, node.key);
            if (node.children == .nodes) {
                for (node.children.nodes.items) |*child| {
                    try collect(allocator, child, arrayList);
                }
            }
        }
    }.collect;

    var firstFrameKeys = try std.ArrayList(u64).initCapacity(std.testing.allocator, 8);
    defer firstFrameKeys.deinit(std.testing.allocator);
    var secondFrameKeys = try std.ArrayList(u64).initCapacity(std.testing.allocator, 8);
    defer secondFrameKeys.deinit(std.testing.allocator);
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        // Build tree: root > [child1, child2 > [nested1, nested2]]
        forbear.element(.{})({
            forbear.element(.{})({});
            forbear.element(.{})({
                forbear.element(.{})({});
                forbear.element(.{})({});
            });
        });
        try collectKeys(std.testing.allocator, &self.frameMeta.?.rootNode.?, &firstFrameKeys);
    });

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            forbear.element(.{})({});
            forbear.element(.{})({
                forbear.element(.{})({});
                forbear.element(.{})({});
            });
        });
        try collectKeys(std.testing.allocator, &self.frameMeta.?.rootNode.?, &secondFrameKeys);
    });

    // Keys should be identical across frames for the same structure
    try std.testing.expectEqual(firstFrameKeys.items.len, secondFrameKeys.items.len);
    try std.testing.expectEqualSlices(u64, firstFrameKeys.items, secondFrameKeys.items);

    // Verify we have the expected number of elements (root + 2 children + 2 nested)
    try std.testing.expectEqual(5, firstFrameKeys.items.len);

    // Verify all keys are unique within a frame
    for (firstFrameKeys.items, 0..) |key, i| {
        for (firstFrameKeys.items[i + 1 ..]) |otherKey| {
            try std.testing.expect(key != otherKey);
        }
    }
}

test "Component resolution" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var callCount: u32 = 0;

    const MyComponentProps = struct {
        callCount: *u32,
        value: u32,
    };

    const MyComponent = (struct {
        fn myComponent(props: MyComponentProps) !void {
            forbear.component("component-resolution-test")({
                props.callCount.* += 1;
                const counter = try forbear.useState(u32, props.value);
                const innerArena = try forbear.useArena();
                try std.testing.expectEqual(10, counter.*);
                forbear.element(.{})({
                    forbear.text(try std.fmt.allocPrint(innerArena, "Value {d}", .{counter.*}));
                });
            });
        }
    }).myComponent;

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            try MyComponent(.{ .callCount = &callCount, .value = 10 });
        });
        try std.testing.expectEqual(1, callCount);
    });

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            try MyComponent(.{ .callCount = &callCount, .value = 20 });
        });
        try std.testing.expectEqual(2, callCount);
    });
}

test "easeInOut" {
    try std.testing.expectEqual(1.0, forbear.easeInOut(1.0));
    try std.testing.expectEqual(0.0, forbear.easeInOut(0.0));
}

test "ease" {
    try std.testing.expectEqual(1.0, forbear.ease(1.0));
    try std.testing.expectEqual(0.0, forbear.ease(0.0));
}

fn resolveSpringTransition(
    arenaAllocator: std.mem.Allocator,
    componentKey: []const u8,
    target: f32,
    config: forbear.SpringConfig,
    result: *f32,
) !void {
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.component(componentKey)({
            result.* = try forbear.useSpringTransition(target, config);
        });
    });
}

test "useSpringTransition - basic convergence" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const target = 100.0;
    const dt = 0.016; // ~60fps

    self.deltaTime = dt;

    // First frame: value should start at target when initialized
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-basic-convergence", target, config, &value);
    try std.testing.expectEqual(target, value);

    // Change target and simulate several frames
    const newTarget = 200.0;
    const initialValue = value;

    // Simulate spring physics over multiple frames
    for (0..100) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-basic-convergence", newTarget, config, &value);
    }

    // After 100 frames, should be very close or converged to target
    const epsilon = 0.001;
    try std.testing.expect(@abs(value - newTarget) < epsilon);
    // Value should have changed from initial
    try std.testing.expect(value != initialValue);
}

test "useSpringTransition - zero delta time" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const target = 50.0;

    self.deltaTime = 0.0;

    // First frame with zero dt
    var value1: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-zero-dt", target, config, &value1);
    try std.testing.expectEqual(target, value1);

    // Second frame with zero dt - should return current value unchanged
    _ = arena.reset(.retain_capacity);
    var value2: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-zero-dt", target + 100.0, config, &value2);
    try std.testing.expectEqual(target, value2);
}

test "useSpringTransition - null delta time" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const target = 75.0;

    self.deltaTime = null;

    // With null delta time, should return current value
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-null-dt", target, config, &value);
    try std.testing.expectEqual(target, value);
}

test "useSpringTransition - small delta time" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const initialTarget = 0.0;
    const newTarget = 100.0;
    const smallDt = 0.001; // 1ms - very small time step

    self.deltaTime = smallDt;

    // Initialize
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-small-dt", initialTarget, config, &value);
    try std.testing.expectEqual(initialTarget, value);

    // Change target with small dt
    _ = arena.reset(.retain_capacity);
    try resolveSpringTransition(arenaAllocator, "spring-small-dt", newTarget, config, &value);

    // Should have moved, but only slightly due to small dt
    try std.testing.expect(value != initialTarget);
    try std.testing.expect(value < newTarget);
    // Movement should be small
    try std.testing.expect(@abs(value - initialTarget) < 10.0);
}

test "useSpringTransition - large delta time" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const initialTarget = 0.0;
    const newTarget = 100.0;
    const largeDt = 1.0; // 1 second - very large frame time

    self.deltaTime = largeDt;

    // Initialize
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-large-dt", initialTarget, config, &value);
    try std.testing.expectEqual(initialTarget, value);

    // Change target with large dt - spring should handle it gracefully
    _ = arena.reset(.retain_capacity);
    try resolveSpringTransition(arenaAllocator, "spring-large-dt", newTarget, config, &value);

    // Should have moved significantly (physics are stable)
    try std.testing.expect(value != initialTarget);
}

test "useSpringTransition - convergence threshold" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const initialTarget = 0.0;
    const newTarget = 100.0;
    const dt = 0.016;

    self.deltaTime = dt;

    // Initialize
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-convergence-threshold", initialTarget, config, &value);
    try std.testing.expectEqual(initialTarget, value);

    // Animate towards target
    var converged = false;
    for (0..1000) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-convergence-threshold", newTarget, config, &value);

        // Check if converged (should snap to exact target within epsilon)
        if (value == newTarget) {
            converged = true;
            break;
        }
    }

    try std.testing.expect(converged);
    try std.testing.expectEqual(newTarget, value);
}

test "useSpringTransition - different spring configurations" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const dt = 0.016;
    self.deltaTime = dt;

    // Test stiff spring (high stiffness, high damping)
    {
        const stiffConfig = forbear.SpringConfig{
            .stiffness = 400.0,
            .damping = 40.0,
            .mass = 1.0,
        };

        var value: f32 = undefined;
        try resolveSpringTransition(arenaAllocator, "spring-stiff-config", 0.0, stiffConfig, &value);
        try std.testing.expectEqual(0.0, value);

        // Should converge quickly
        for (0..50) |_| {
            _ = arena.reset(.retain_capacity);
            try resolveSpringTransition(arenaAllocator, "spring-stiff-config", 100.0, stiffConfig, &value);
        }

        const epsilon = 0.1;
        try std.testing.expect(@abs(value - 100.0) < epsilon);
    }

    // Test soft spring (low stiffness, low damping)
    {
        const softConfig = forbear.SpringConfig{
            .stiffness = 50.0,
            .damping = 5.0,
            .mass = 1.0,
        };

        _ = arena.reset(.retain_capacity);
        var value: f32 = undefined;
        try resolveSpringTransition(arenaAllocator, "spring-soft-config", 0.0, softConfig, &value);
        try std.testing.expectEqual(0.0, value);

        // Should move more slowly
        for (0..10) |_| {
            _ = arena.reset(.retain_capacity);
            try resolveSpringTransition(arenaAllocator, "spring-soft-config", 100.0, softConfig, &value);
        }

        // After 10 frames, should not be fully converged yet
        try std.testing.expect(@abs(value - 100.0) > 1.0);
    }
}

test "useSpringTransition - heavy mass" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const heavyConfig = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 10.0, // Heavy mass
    };
    const dt = 0.016;

    self.deltaTime = dt;

    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-heavy-mass", 0.0, heavyConfig, &value);
    try std.testing.expectEqual(0.0, value);

    // Heavy mass should result in slower acceleration
    _ = arena.reset(.retain_capacity);
    try resolveSpringTransition(arenaAllocator, "spring-heavy-mass", 100.0, heavyConfig, &value);

    // After one frame, movement should be relatively small due to mass
    try std.testing.expect(@abs(value) < 50.0);
}

test "useSpringTransition - target changes during animation" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const dt = 0.016;

    self.deltaTime = dt;

    // Initialize at 0
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-target-changes", 0.0, config, &value);
    try std.testing.expectEqual(0.0, value);

    // Animate towards 100 for a few frames
    for (0..10) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-target-changes", 100.0, config, &value);
    }
    const valueAfter10Frames = value;

    // Suddenly change target to 200
    for (0..20) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-target-changes", 200.0, config, &value);
    }

    // Should have moved past the first target
    try std.testing.expect(value > valueAfter10Frames);
    try std.testing.expect(value > 100.0);
}

test "useSpringTransition - negative values" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const dt = 0.016;

    self.deltaTime = dt;

    // Initialize at positive value
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-negative-values", 100.0, config, &value);
    try std.testing.expectEqual(100.0, value);

    // Transition to negative target
    for (0..100) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-negative-values", -50.0, config, &value);
    }

    // Should converge to negative target
    const epsilon = 0.1;
    try std.testing.expect(@abs(value - (-50.0)) < epsilon);
}

test "useSpringTransition - state persistence across frames" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const dt = 0.016;
    self.deltaTime = dt;

    // Frame 1
    var value1: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-state-persistence", 0.0, config, &value1);
    try std.testing.expectEqual(0.0, value1);

    // Frame 2 - change target
    _ = arena.reset(.retain_capacity);
    var value2: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-state-persistence", 100.0, config, &value2);

    // Frame 3 - should continue from where it left off
    _ = arena.reset(.retain_capacity);
    var value3: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-state-persistence", 100.0, config, &value3);

    // Value should continue progressing
    try std.testing.expect(value3 >= value2 or @abs(value3 - 100.0) < 0.0001);
}

test "State creation with manual handling" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();
    var componentKey: u64 = undefined;
    {
        // First run that should allocate RAM, and still allow reading and writing the values
        try forbear.frame(try utilities.frameMeta(arenaAllocator))({
            forbear.component("random")({
                componentKey = self.frameMeta.?.componentResolutionState.getLast().key;
                const state1 = try forbear.useState(i32, 42);
                try std.testing.expectEqual(1, self.componentStates.get(componentKey).?.items.len);
                try std.testing.expectEqual(@sizeOf(i32), self.componentStates.get(componentKey).?.items[0].len);
                try std.testing.expectEqual(42, state1.*);

                const state2 = try forbear.useState(f32, 3.14);
                try std.testing.expectEqual(2, self.componentStates.get(componentKey).?.items.len);
                try std.testing.expectEqual(@sizeOf(f32), self.componentStates.get(componentKey).?.items[1].len);
                try std.testing.expectEqual(42, state1.*);
                try std.testing.expectEqual(3.14, state2.*);

                state1.* = 100;
                state2.* = 6.28;
                try std.testing.expectEqual(100, state1.*);
                try std.testing.expectEqual(6.28, state2.*);
            });
        });
    }
    {
        _ = arena.reset(.retain_capacity);
        try forbear.frame(try utilities.frameMeta(arenaAllocator))({
            forbear.component("random")({
                const state1 = try forbear.useState(i32, 42);
                try std.testing.expectEqual(2, self.componentStates.get(componentKey).?.items.len);
                try std.testing.expectEqual(@sizeOf(i32), self.componentStates.get(componentKey).?.items[0].len);
                const state2 = try forbear.useState(f32, 3.14);
                try std.testing.expectEqual(2, self.componentStates.get(componentKey).?.items.len);
                try std.testing.expectEqual(@sizeOf(f32), self.componentStates.get(componentKey).?.items[1].len);

                try std.testing.expectEqual(100, state1.*);
                try std.testing.expectEqual(6.28, state2.*);
            });
        });
    }
    {
        _ = arena.reset(.retain_capacity);
        try forbear.frame(try utilities.frameMeta(arenaAllocator))({
            try std.testing.expectError(error.NoComponentContext, forbear.useState(i32, 42));
        });
    }
}

test "Multiple useState pointers remain valid after realloc (useTransition pattern)" {
    // This test reproduces the useTransition scenario: three sequential useState
    // calls in the same component on the first frame. If realloc moves the buffer,
    // earlier pointers would be invalidated causing a segfault.
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    {
        // First frame: all three useState calls allocate/grow the buffer
        try forbear.frame(try utilities.frameMeta(arenaAllocator))({
            forbear.component("use-transition-realloc-test")({
                // Mimics useTransition's calls:
                //   const valueToTransitionFrom = try useState(f32, value);
                //   const valueToTransitionTo = try useState(f32, value);
                //   const animation = try useAnimation(duration);  -> useState(?AnimationState, null)
                const valueToTransitionFrom = try forbear.useState(f32, 1.0);
                try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
                const valueToTransitionTo = try forbear.useState(f32, 1.0);
                try std.testing.expectEqual(1.0, valueToTransitionTo.*);
                const animationState = try forbear.useState(?forbear.AnimationState, null);
                try std.testing.expectEqual(null, animationState.*);

                // These dereferences should not segfault — if realloc moved the buffer,
                // earlier pointers would be dangling and this would crash or read garbage.
                try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
                try std.testing.expectEqual(1.0, valueToTransitionTo.*);
                try std.testing.expectEqual(null, animationState.*);

                // Simulate the comparison from useTransition line 419:
                //   if (value != valueToTransitionTo.*) { ... }
                const value: f32 = 2.0;
                if (value != valueToTransitionTo.*) {
                    valueToTransitionTo.* = value;
                }
                try std.testing.expectEqual(2.0, valueToTransitionTo.*);
                // The first pointer should still be valid and unchanged
                try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
            });
        });
    }

    {
        // Second frame: buffer already exists at full size, no realloc needed
        _ = arena.reset(.retain_capacity);
        try forbear.frame(try utilities.frameMeta(arenaAllocator))({
            forbear.component("use-transition-realloc-test")({
                const valueToTransitionFrom = try forbear.useState(f32, 1.0);
                const valueToTransitionTo = try forbear.useState(f32, 1.0);
                const animationState = try forbear.useState(?forbear.AnimationState, null);

                // Second frame should preserve mutated state from first frame
                try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
                try std.testing.expectEqual(2.0, valueToTransitionTo.*);
                try std.testing.expectEqual(null, animationState.*);
            });
        });
    }
}

test "Event queue dispatches events to correct elements" {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            forbear.element(.{})({});
            const firstChildKey = self.frameMeta.?.previousPushedNode.?.key;

            forbear.element(.{})({});
            const secondChildKey = self.frameMeta.?.previousPushedNode.?.key;

            try std.testing.expect(firstChildKey != secondChildKey);

            try forbear.pushEvent(firstChildKey, .mouseOver);
            try forbear.pushEvent(firstChildKey, .mouseOut);
            try forbear.pushEvent(secondChildKey, .mouseOver);
        });
    });

    _ = arena.reset(.retain_capacity);

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            forbear.element(.{})({});
            const firstChildKey = self.frameMeta.?.previousPushedNode.?.key;

            try std.testing.expectEqual(forbear.Event.mouseOut, forbear.useNextEvent().?);
            try std.testing.expectEqual(forbear.Event.mouseOver, forbear.useNextEvent().?);
            try std.testing.expectEqual(null, forbear.useNextEvent());

            forbear.element(.{})({});
            const secondChildKey = self.frameMeta.?.previousPushedNode.?.key;

            try std.testing.expect(firstChildKey != secondChildKey);

            try std.testing.expectEqual(forbear.Event.mouseOver, forbear.useNextEvent().?);
            try std.testing.expectEqual(null, forbear.useNextEvent());
        });
    });
}

fn testCreateElementConfiguration(configuration: struct {
    style: forbear.IncompleteStyle,
    expectedSize: Vec2,
}) !void {
    const allocator = std.testing.allocator;
    try forbear.init(allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(configuration.style)({});
        if (self.frameMeta.?.previousPushedNode) |previousNode| {
            try std.testing.expectEqualDeep(configuration.expectedSize, previousNode.size);
        }
    });
}

test "element - width ratio uses fixed height" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .ratio = 1.5 },
            .height = .{ .fixed = 40.0 },
        },
        .expectedSize = .{ 60.0, 40.0 },
    });
}

test "element - height ratio uses fixed width" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .fixed = 40.0 },
            .height = .{ .ratio = 1.5 },
        },
        .expectedSize = .{ 40.0, 60.0 },
    });
}

test "element - ratio without opposite fixed axis starts at zero" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .ratio = 2.0 },
            .height = .fit,
        },
        .expectedSize = .{ 0.0, 0.0 },
    });
}

test "element - percentage sizing starts at zero before parent resolution" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .percentage = 0.5 },
            .height = .{ .percentage = 0.5 },
        },
        .expectedSize = .{ 0.0, 0.0 },
    });
}

test "element fitting - fit parent with padding accumulates fixed child inline" {
    // A topToBottom fit parent with padding should grow its height by the
    // child's height plus margins, plus its own padding/border.
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .topToBottom,
            .height = .fit,
            .width = .{ .fixed = 100.0 },
            .padding = forbear.Padding.block(10.0),
        })({
            forbear.element(.{
                .width = .{ .fixed = 40.0 },
                .height = .{ .fixed = 20.0 },
                .margin = forbear.Margin.block(5.0),
            })({});
        });
        const parent = self.frameMeta.?.previousPushedNode.?;
        // height = padding(10+10) + margin(5+5) + child(20) = 50
        try std.testing.expectEqual(@as(f32, 50.0), parent.size[1]);
        try std.testing.expectEqual(@as(f32, 50.0), parent.minSize[1]);
    });
}

test "element fitting - fit parent cross-axis takes max child height" {
    // A leftToRight fit parent fitting height should use the tallest child
    // contribution plus its own vertical padding.
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .height = .fit,
            .width = .{ .fixed = 200.0 },
            .padding = forbear.Padding.block(8.0),
        })({
            forbear.element(.{
                .width = .{ .fixed = 30.0 },
                .height = .{ .fixed = 20.0 },
            })({});
            forbear.element(.{
                .width = .{ .fixed = 30.0 },
                .height = .{ .fixed = 50.0 },
            })({});
        });
        const parent = self.frameMeta.?.previousPushedNode.?;
        // height = padding(8+8) + max child height(50) = 66
        try std.testing.expectEqual(@as(f32, 66.0), parent.size[1]);
        try std.testing.expectEqual(@as(f32, 66.0), parent.minSize[1]);
    });
}

test "element fitting - fit parent with padding accumulates fixed child inline width" {
    // A leftToRight fit parent should sum child widths plus margins plus its
    // own horizontal padding.
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .fit,
            .height = .{ .fixed = 50.0 },
            .padding = forbear.Padding.inLine(12.0),
        })({
            forbear.element(.{
                .width = .{ .fixed = 30.0 },
                .height = .{ .fixed = 50.0 },
                .margin = forbear.Margin.inLine(4.0),
            })({});
            forbear.element(.{
                .width = .{ .fixed = 20.0 },
                .height = .{ .fixed = 50.0 },
                .margin = forbear.Margin.inLine(6.0),
            })({});
        });
        const parent = self.frameMeta.?.previousPushedNode.?;
        // width = padding(12+12) + child0(4+30+4) + child1(6+20+6) = 94
        try std.testing.expectEqual(@as(f32, 94.0), parent.size[0]);
        try std.testing.expectEqual(@as(f32, 94.0), parent.minSize[0]);
    });
}

test "element fitting - nested fit parents propagate size upward" {
    // Inner fit parent should size to its child, outer fit parent should size
    // to the inner parent. Both measured before layout().
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .topToBottom,
            .width = .fit,
            .height = .fit,
        })({
            forbear.element(.{
                .direction = .topToBottom,
                .width = .fit,
                .height = .fit,
            })({
                forbear.element(.{
                    .width = .{ .fixed = 60.0 },
                    .height = .{ .fixed = 30.0 },
                })({});
            });
        });
        const outer = self.frameMeta.?.previousPushedNode.?;
        try std.testing.expectEqual(@as(f32, 60.0), outer.size[0]);
        try std.testing.expectEqual(@as(f32, 30.0), outer.size[1]);
        try std.testing.expectEqual(@as(f32, 60.0), outer.minSize[0]);
        try std.testing.expectEqual(@as(f32, 30.0), outer.minSize[1]);
    });
}

test "element fitting - manual child does not contribute to fit parent" {
    // A manually-placed child should be excluded from the parent's fit
    // calculation.
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .topToBottom,
            .width = .fit,
            .height = .fit,
        })({
            forbear.element(.{
                .placement = .{ .manual = .{ 0.0, 0.0 } },
                .width = .{ .fixed = 999.0 },
                .height = .{ .fixed = 999.0 },
            })({});
        });
        const parent = self.frameMeta.?.previousPushedNode.?;
        // Manual child must not inflate the fit parent
        try std.testing.expectEqual(@as(f32, 0.0), parent.size[0]);
        try std.testing.expectEqual(@as(f32, 0.0), parent.size[1]);
    });
}

test "element fitting - text child inflates fit parent inline" {
    // A fit parent whose only child is a text node should grow to contain the
    // text's full single-line width and height before layout() runs.
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .fit,
            .height = .fit,
        })({
            forbear.text("hello");
        });
        const parent = self.frameMeta.?.previousPushedNode.?;
        // Parent must be at least as wide and tall as the text node itself.
        const textNode = parent.children.nodes.items[0];
        try std.testing.expect(parent.size[0] >= textNode.size[0]);
        try std.testing.expect(parent.size[1] >= textNode.size[1]);
        try std.testing.expect(parent.size[0] > 0.0);
        try std.testing.expect(parent.size[1] > 0.0);
    });
}

test "element fitting - word-wrapped text child inflates fit parent to full text width" {
    // When textWrapping = .word, the text node's size[0] is the full unwrapped
    // width. A fit parent must pick that up during definition so it is not
    // collapsed to the minimum-word width before layout runs.
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .leftToRight,
            .width = .fit,
            .height = .fit,
            .textWrapping = .word,
        })({
            forbear.text("hello world");
        });
        const parent = self.frameMeta.?.previousPushedNode.?;
        const textNode = parent.children.nodes.items[0];
        // The full text width (size[0]) must be reflected in the parent —
        // not just the longest-word minSize.
        try std.testing.expectEqual(textNode.size[0], parent.size[0]);
        try std.testing.expect(parent.size[0] > textNode.minSize[0]);
    });
}

fn resolveTransition(
    arenaAllocator: std.mem.Allocator,
    key: []const u8,
    value: f32,
    duration: f32,
    easing: fn (f32) f32,
    result: *f32,
) !void {
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.component(key)({
            result.* = try forbear.useTransition(value, duration, easing);
        });
    });
}

const AnimationCommand = enum {
    none,
    start,
    reset,
};

const AnimationSnapshot = struct {
    running: bool,
    progress: ?f32,
};

fn resolveAnimation(
    arenaAllocator: std.mem.Allocator,
    key: []const u8,
    duration: f32,
    command: AnimationCommand,
    snapshot: *AnimationSnapshot,
) !void {
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.component(key)({
            const animation = try forbear.useAnimation(duration);
            switch (command) {
                .none => {},
                .start => animation.start(),
                .reset => animation.reset(),
            }
            snapshot.* = .{
                .running = animation.isRunning(),
                .progress = animation.progress(),
            };
        });
    });
}

fn expectApprox(expected: f32, actual: f32) !void {
    try std.testing.expectApproxEqAbs(expected, actual, 0.001);
}

fn testImageStyleResolution(configuration: struct {
    style: forbear.IncompleteStyle,
    expectedWidth: Sizing,
    expectedHeight: Sizing,
    expectedSize: Vec2,
    expectedMinSize: Vec2,
}) !void {
    try forbear.init(std.testing.allocator, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var image = forbear.Image{
        .image = undefined,
        .imageExtent = undefined,
        .imageView = undefined,
        .memory = undefined,
        .contents = &.{},
        .loaded = false,
        .width = 200,
        .height = 100,
        .renderer = undefined,
    };

    const self = forbear.getContext();
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.image(configuration.style, &image);
        const node = self.frameMeta.?.previousPushedNode.?;
        try std.testing.expectEqualDeep(configuration.expectedWidth, node.style.width);
        try std.testing.expectEqualDeep(configuration.expectedHeight, node.style.height);
        try std.testing.expectEqualDeep(configuration.expectedSize, node.size);
        try std.testing.expectEqualDeep(configuration.expectedMinSize, node.minSize);
        switch (node.style.background) {
            .image => |backgroundImage| try std.testing.expect(backgroundImage == &image),
            else => return error.ExpectedImageBackground,
        }
    });
}

test "cubicBezier - edge cases clamp to unit interval" {
    try std.testing.expectEqual(@as(f32, 0.0), forbear.cubicBezier(0.25, 0.1, 0.25, 1.0, -1.0));
    try std.testing.expectEqual(@as(f32, 0.0), forbear.cubicBezier(0.25, 0.1, 0.25, 1.0, 0.0));
    try std.testing.expectEqual(@as(f32, 1.0), forbear.cubicBezier(0.25, 0.1, 0.25, 1.0, 1.0));
    try std.testing.expectEqual(@as(f32, 1.0), forbear.cubicBezier(0.25, 0.1, 0.25, 1.0, 2.0));
}

test "cubicBezier - linear control points match input" {
    for ([_]f32{ 0.1, 0.25, 0.5, 0.75, 0.9 }) |time| {
        try expectApprox(time, forbear.cubicBezier(0.0, 0.0, 1.0, 1.0, time));
    }
}

test "cubicBezier - known easing values stay stable" {
    try expectApprox(0.8024034, forbear.cubicBezier(0.25, 0.1, 0.25, 1.0, 0.5));
    try expectApprox(0.5, forbear.cubicBezier(0.5, 0.0, 0.5, 1.0, 0.5));
}

test "linear - identity" {
    try std.testing.expectEqual(@as(f32, 0.0), forbear.linear(0.0));
    try std.testing.expectEqual(@as(f32, 0.5), forbear.linear(0.5));
    try std.testing.expectEqual(@as(f32, 1.0), forbear.linear(1.0));
}

test "useTransition - initial value, interpolation, and completion" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();

    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    self.deltaTime = 0.0;
    var value: f32 = undefined;
    try resolveTransition(arenaAllocator, "transition-basic", 0.0, 1.0, forbear.linear, &value);
    try std.testing.expectEqual(@as(f32, 0.0), value);

    self.deltaTime = 0.25;
    _ = arena.reset(.retain_capacity);
    try resolveTransition(arenaAllocator, "transition-basic", 100.0, 1.0, forbear.linear, &value);
    try std.testing.expectEqual(@as(f32, 0.0), value);

    _ = arena.reset(.retain_capacity);
    try resolveTransition(arenaAllocator, "transition-basic", 100.0, 1.0, forbear.linear, &value);
    try expectApprox(25.0, value);

    _ = arena.reset(.retain_capacity);
    try resolveTransition(arenaAllocator, "transition-basic", 100.0, 1.0, forbear.linear, &value);
    try expectApprox(50.0, value);

    self.deltaTime = 1.0;
    _ = arena.reset(.retain_capacity);
    try resolveTransition(arenaAllocator, "transition-basic", 100.0, 1.0, forbear.linear, &value);
    try std.testing.expectEqual(@as(f32, 100.0), value);
}

test "useTransition - changing target mid animation restarts from current value" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();

    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    self.deltaTime = 0.0;
    var value: f32 = undefined;
    try resolveTransition(arenaAllocator, "transition-retarget", 0.0, 1.0, forbear.linear, &value);

    self.deltaTime = 0.5;
    _ = arena.reset(.retain_capacity);
    try resolveTransition(arenaAllocator, "transition-retarget", 100.0, 1.0, forbear.linear, &value);
    try std.testing.expectEqual(@as(f32, 0.0), value);

    _ = arena.reset(.retain_capacity);
    try resolveTransition(arenaAllocator, "transition-retarget", 100.0, 1.0, forbear.linear, &value);
    try expectApprox(50.0, value);

    _ = arena.reset(.retain_capacity);
    try resolveTransition(arenaAllocator, "transition-retarget", 200.0, 1.0, forbear.linear, &value);
    try expectApprox(100.0, value);

    _ = arena.reset(.retain_capacity);
    try resolveTransition(arenaAllocator, "transition-retarget", 200.0, 1.0, forbear.linear, &value);
    try expectApprox(150.0, value);
}

test "useAnimation - start advances progress and reset clears state" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, renderer);
    defer forbear.deinit();

    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var snapshot: AnimationSnapshot = undefined;

    self.deltaTime = null;
    try resolveAnimation(arenaAllocator, "animation-lifecycle", 1.0, .none, &snapshot);
    try std.testing.expect(!snapshot.running);
    try std.testing.expectEqual(@as(?f32, null), snapshot.progress);

    self.deltaTime = 0.0;
    _ = arena.reset(.retain_capacity);
    try resolveAnimation(arenaAllocator, "animation-lifecycle", 1.0, .start, &snapshot);
    try std.testing.expect(snapshot.running);
    try std.testing.expectEqual(@as(?f32, 0.0), snapshot.progress);

    self.deltaTime = 0.25;
    _ = arena.reset(.retain_capacity);
    try resolveAnimation(arenaAllocator, "animation-lifecycle", 1.0, .none, &snapshot);
    try std.testing.expect(snapshot.running);
    try expectApprox(0.25, snapshot.progress.?);

    self.deltaTime = 2.0;
    _ = arena.reset(.retain_capacity);
    try resolveAnimation(arenaAllocator, "animation-lifecycle", 1.0, .none, &snapshot);
    try std.testing.expect(snapshot.running);
    try std.testing.expectEqual(@as(?f32, 1.0), snapshot.progress);

    _ = arena.reset(.retain_capacity);
    try resolveAnimation(arenaAllocator, "animation-lifecycle", 1.0, .reset, &snapshot);
    try std.testing.expect(!snapshot.running);
    try std.testing.expectEqual(@as(?f32, null), snapshot.progress);
}

test "image - fit fit resolves to intrinsic width and aspect ratio height" {
    try testImageStyleResolution(.{
        .style = .{
            .width = .fit,
            .height = .fit,
        },
        .expectedWidth = .{ .fixed = 200.0 },
        .expectedHeight = .{ .ratio = 0.5 },
        .expectedSize = .{ 200.0, 100.0 },
        .expectedMinSize = .{ 0.0, 0.0 },
    });
}

test "image - fixed fit resolves ratio height from aspect" {
    try testImageStyleResolution(.{
        .style = .{
            .width = .{ .fixed = 80.0 },
            .height = .fit,
        },
        .expectedWidth = .{ .fixed = 80.0 },
        .expectedHeight = .{ .ratio = 0.5 },
        .expectedSize = .{ 80.0, 40.0 },
        .expectedMinSize = .{ 80.0, 0.0 },
    });
}

test "image - grow fit keeps grow width and derives ratio height" {
    try testImageStyleResolution(.{
        .style = .{
            .width = .grow,
            .height = .fit,
        },
        .expectedWidth = .grow,
        .expectedHeight = .{ .ratio = 0.5 },
        .expectedSize = .{ 0.0, 0.0 },
        .expectedMinSize = .{ 0.0, 0.0 },
    });
}

test "image - fit fixed derives ratio width from aspect" {
    try testImageStyleResolution(.{
        .style = .{
            .width = .fit,
            .height = .{ .fixed = 40.0 },
        },
        .expectedWidth = .{ .ratio = 2.0 },
        .expectedHeight = .{ .fixed = 40.0 },
        .expectedSize = .{ 80.0, 40.0 },
        .expectedMinSize = .{ 0.0, 40.0 },
    });
}

test "image - grow grow keeps grow width and derives ratio height" {
    try testImageStyleResolution(.{
        .style = .{
            .width = .grow,
            .height = .grow,
        },
        .expectedWidth = .grow,
        .expectedHeight = .{ .ratio = 0.5 },
        .expectedSize = .{ 0.0, 0.0 },
        .expectedMinSize = .{ 0.0, 0.0 },
    });
}
