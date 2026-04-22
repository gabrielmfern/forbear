const std = @import("std");
const forbear = @import("../root.zig");
const layouting = @import("../layouting.zig");
const layout = layouting.layout;
const utilities = @import("utilities.zig");
const Vec2 = @Vector(2, f32);

test "Element tree stack stability" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            const nodeParentStack = &self.frameMeta.?.nodeParentStack;
            try std.testing.expectEqual(1, nodeParentStack.items.len);
            forbear.FpsCounter();

            try std.testing.expectEqual(1, nodeParentStack.items.len);
            forbear.element(.{})({
                try std.testing.expectEqual(2, nodeParentStack.items.len);

                forbear.text("Hello, world!");
                try std.testing.expectEqual(2, nodeParentStack.items.len);

                forbear.element(.{})({
                    try std.testing.expectEqual(3, nodeParentStack.items.len);

                    forbear.text("Nested element");
                    try std.testing.expectEqual(3, nodeParentStack.items.len);
                });

                try std.testing.expectEqual(2, nodeParentStack.items.len);
            });
            try std.testing.expectEqual(1, nodeParentStack.items.len);
        });
        try std.testing.expectEqual(0, self.frameMeta.?.nodeParentStack.items.len);
        try std.testing.expect(self.nodeTree.list.items.len > 0);
    });

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            const nodeParentStack = &self.frameMeta.?.nodeParentStack;
            try std.testing.expectEqual(1, nodeParentStack.items.len);
            forbear.FpsCounter();
            try std.testing.expectEqual(1, nodeParentStack.items.len);
            forbear.element(.{})({
                try std.testing.expectEqual(2, nodeParentStack.items.len);

                forbear.text("Hello, world!");
                try std.testing.expectEqual(2, nodeParentStack.items.len);

                forbear.element(.{})({
                    try std.testing.expectEqual(3, nodeParentStack.items.len);

                    forbear.text("Nested element");
                    try std.testing.expectEqual(3, nodeParentStack.items.len);
                });

                try std.testing.expectEqual(2, nodeParentStack.items.len);
            });
            try std.testing.expectEqual(1, nodeParentStack.items.len);
        });
        try std.testing.expectEqual(0, self.frameMeta.?.nodeParentStack.items.len);
        try std.testing.expect(self.nodeTree.list.items.len > 0);
    });
}

test "Element key stability across frames" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    // Helper to collect keys from the tree
    const collectKeys = struct {
        fn collect(
            allocator: std.mem.Allocator,
            tree: *const forbear.NodeTree,
            nodeIndex: usize,
            arrayList: *std.ArrayList(u64),
        ) !void {
            const node = tree.at(nodeIndex);
            try arrayList.append(allocator, node.key);
            var childIndex = node.firstChild;
            while (childIndex) |idx| {
                try collect(allocator, tree, idx, arrayList);
                childIndex = tree.at(idx).nextSibling;
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
        try collectKeys(std.testing.allocator, &self.nodeTree, 0, &firstFrameKeys);
    });

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            forbear.element(.{})({});
            forbear.element(.{})({
                forbear.element(.{})({});
                forbear.element(.{})({});
            });
        });
        try collectKeys(std.testing.allocator, &self.nodeTree, 0, &secondFrameKeys);
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
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
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
                const counter = forbear.useState(u32, props.value);
                const innerArena = forbear.useArena();
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
            result.* = forbear.useSpringTransition(target, config);
        });
    });
}

test "useSpringTransition - basic convergence" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

    // With null delta time, should return current value
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-null-dt", target, config, &value);
    try std.testing.expectEqual(target, value);
}

test "useSpringTransition - small delta time" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getContext();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const dt = 0.016;
    self.deltaTime = dt;
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
    self.cappedDeltaTime = self.deltaTime;

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
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
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
                const state1 = forbear.useState(i32, 42);
                try std.testing.expectEqual(1, self.componentStates.get(componentKey).?.items.len);
                try std.testing.expectEqual(@sizeOf(i32), self.componentStates.get(componentKey).?.items[0].len);
                try std.testing.expectEqual(42, state1.*);

                const state2 = forbear.useState(f32, 3.14);
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
                const state1 = forbear.useState(i32, 42);
                try std.testing.expectEqual(2, self.componentStates.get(componentKey).?.items.len);
                try std.testing.expectEqual(@sizeOf(i32), self.componentStates.get(componentKey).?.items[0].len);
                const state2 = forbear.useState(f32, 3.14);
                try std.testing.expectEqual(2, self.componentStates.get(componentKey).?.items.len);
                try std.testing.expectEqual(@sizeOf(f32), self.componentStates.get(componentKey).?.items[1].len);

                try std.testing.expectEqual(100, state1.*);
                try std.testing.expectEqual(6.28, state2.*);
            });
        });
    }
    // {
    //     _ = arena.reset(.retain_capacity);
    //     // useState called outside a component captures NoComponentContext in frameMeta.err
    //     try std.testing.expectError(
    //         error.NoComponentContext,
    //         forbear.frame(try utilities.frameMeta(arenaAllocator))({
    //             _ = forbear.useState(i32, 42);
    //         }),
    //     );
    // }
}

test "Multiple useState pointers remain valid after realloc (useTransition pattern)" {
    // This test reproduces the useTransition scenario: three sequential useState
    // calls in the same component on the first frame. If realloc moves the buffer,
    // earlier pointers would be invalidated causing a segfault.
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    {
        // First frame: all three useState calls allocate/grow the buffer
        try forbear.frame(try utilities.frameMeta(arenaAllocator))({
            forbear.component("use-transition-realloc-test")({
                // Mimics useTransition's calls:
                //   const valueToTransitionFrom = useState(f32, value);
                //   const valueToTransitionTo = useState(f32, value);
                //   const animation = useAnimation(duration);  -> useState(?AnimationState, null)
                const valueToTransitionFrom = forbear.useState(f32, 1.0);
                try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
                const valueToTransitionTo = forbear.useState(f32, 1.0);
                try std.testing.expectEqual(1.0, valueToTransitionTo.*);
                const animationState = forbear.useState(?forbear.AnimationState, null);
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
                const valueToTransitionFrom = forbear.useState(f32, 1.0);
                const valueToTransitionTo = forbear.useState(f32, 1.0);
                const animationState = forbear.useState(?forbear.AnimationState, null);

                // Second frame should preserve mutated state from first frame
                try std.testing.expectEqual(1.0, valueToTransitionFrom.*);
                try std.testing.expectEqual(2.0, valueToTransitionTo.*);
                try std.testing.expectEqual(null, animationState.*);
            });
        });
    }
}

test "Event queue dispatches events to correct elements" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            forbear.element(.{})({});
            const firstChildKey = forbear.getPreviousNode().?.key;

            forbear.element(.{})({});
            const secondChildKey = forbear.getPreviousNode().?.key;

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
            const firstChildKey = forbear.getPreviousNode().?.key;

            try std.testing.expectEqual(forbear.Event.mouseOut, forbear.useNextEvent().?);
            try std.testing.expectEqual(forbear.Event.mouseOver, forbear.useNextEvent().?);
            try std.testing.expectEqual(null, forbear.useNextEvent());

            forbear.element(.{})({});
            const secondChildKey = forbear.getPreviousNode().?.key;

            try std.testing.expect(firstChildKey != secondChildKey);

            try std.testing.expectEqual(forbear.Event.mouseOver, forbear.useNextEvent().?);
            try std.testing.expectEqual(null, forbear.useNextEvent());
        });
    });
}

test "on() returns matching events inside element body" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // Frame 1: build elements and push events
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            forbear.element(.{})({});
            const childKey = forbear.getPreviousNode().?.key;

            try forbear.pushEvent(childKey, .mouseOver);
            try forbear.pushEvent(childKey, .mouseOut);
        });
    });

    _ = arena.reset(.retain_capacity);

    // Frame 2: use on() inside element body to consume specific events
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            forbear.element(.{})({
                // on(.mouseOut) should find and return the mouseOut event,
                // even though mouseOver was pushed first
                try std.testing.expect(forbear.on(.mouseOut));
                // on(.mouseOver) should still find mouseOver since only mouseOut was consumed
                try std.testing.expect(forbear.on(.mouseOver));
                // No more events of either type
                try std.testing.expect(!forbear.on(.mouseOver));
                try std.testing.expect(!forbear.on(.mouseOut));
            });
        });
    });
}

fn testCreateElementConfiguration(configuration: struct {
    style: forbear.Style,
    expectedSize: Vec2,
}) !void {
    const allocator = std.testing.allocator;
    try forbear.init(allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(configuration.style)({});
        if (forbear.getPreviousNode()) |previousNode| {
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

test "element fitting - fixed child does not contribute to fit parent" {
    // A fixed-placed child should be excluded from the parent's fit
    // calculation.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .vertical,
            .width = .fit,
            .height = .fit,
        })({
            forbear.element(.{
                .placement = .{ .fixed = .{ 0.0, 0.0 } },
                .width = .{ .fixed = 999.0 },
                .height = .{ .fixed = 999.0 },
            })({});
        });
        const parent = forbear.getPreviousNode().?;
        // Fixed child must not inflate the fit parent
        try std.testing.expectEqual(@as(f32, 0.0), parent.size[0]);
        try std.testing.expectEqual(@as(f32, 0.0), parent.size[1]);
    });
}

test "element fitting - text child inflates fit parent inline" {
    // A fit parent whose only child is a text node should grow to contain the
    // text's full single-line width and height before layout() runs.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .horizontal,
            .width = .fit,
            .height = .fit,
        })({
            forbear.text("hello");
        });
        const parent = forbear.getPreviousNode().?;
        // Parent must be at least as wide and tall as the text node itself.
        const textNode = self.nodeTree.at(parent.firstChild.?);
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
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .direction = .horizontal,
            .width = .fit,
            .height = .fit,
            .textWrapping = .word,
        })({
            forbear.text("hello world");
        });
        const parent = forbear.getPreviousNode().?;
        const textNode = self.nodeTree.at(parent.firstChild.?);
        // The full text width (size[0]) must be reflected in the parent —
        // not just the longest-word minSize.
        try std.testing.expectEqual(textNode.size[0], parent.size[0]);
        try std.testing.expect(parent.size[0] > textNode.minSize[0]);
    });
}

test "mouseDown dispatches on button press" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getContext();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // Frame 1: create an element and run layout + update with mouse press
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({});

        _ = try layout();

        self.mousePosition = .{ 50.0, 50.0 };
        self.mouseButtonJustPressed = true;
        self.mouseButtonPressed = true;
        try forbear.update();
    });

    _ = arena.reset(.retain_capacity);

    // Frame 2: consume events
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({
            try std.testing.expect(forbear.on(.mouseDown));
        });
    });
}

test "mouseUp dispatches on button release" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getContext();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({});

        _ = try layout();

        self.mousePosition = .{ 50.0, 50.0 };
        self.mouseButtonJustReleased = true;
        self.mouseButtonPressed = false;
        try forbear.update();
    });

    _ = arena.reset(.retain_capacity);

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({
            try std.testing.expect(forbear.on(.mouseUp));
        });
    });
}

test "click fires when mouseDown and mouseUp on same element" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getContext();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // Frame 1: mouseDown
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({});

        _ = try layout();

        self.mousePosition = .{ 50.0, 50.0 };
        self.mouseButtonJustPressed = true;
        self.mouseButtonPressed = true;
        try forbear.update();
    });

    _ = arena.reset(.retain_capacity);

    // Frame 2: mouseUp on same element
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({});

        _ = try layout();

        self.mousePosition = .{ 50.0, 50.0 };
        self.mouseButtonJustPressed = false;
        self.mouseButtonJustReleased = true;
        self.mouseButtonPressed = false;
        try forbear.update();
    });

    _ = arena.reset(.retain_capacity);

    // Frame 3: consume events
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({
            try std.testing.expect(forbear.on(.click));
            try std.testing.expect(forbear.on(.mouseUp));
        });
    });
}

test "no click when mouse moves away between mouseDown and mouseUp" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getContext();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // Frame 1: mouseDown on element
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({});

        _ = try layout();

        self.mousePosition = .{ 50.0, 50.0 };
        self.mouseButtonJustPressed = true;
        self.mouseButtonPressed = true;
        try forbear.update();
    });

    _ = arena.reset(.retain_capacity);

    // Frame 2: move mouse outside and release
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({});

        _ = try layout();

        self.mousePosition = .{ 200.0, 200.0 };
        self.mouseButtonJustPressed = false;
        self.mouseButtonJustReleased = true;
        self.mouseButtonPressed = false;
        try forbear.update();
    });

    _ = arena.reset(.retain_capacity);

    // Frame 3: consume events -- should have mouseOut but no click or mouseUp on this element
    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        })({
            try std.testing.expect(!forbear.on(.click));
            try std.testing.expect(!forbear.on(.mouseUp));
        });
    });
}

// --- Component children slotting tests ---

fn collectChildIndices(tree: *const forbear.NodeTree, parentIndex: usize, buf: []usize) []usize {
    var count: usize = 0;
    var childOpt = tree.at(parentIndex).firstChild;
    while (childOpt) |childIndex| {
        if (count < buf.len) {
            buf[count] = childIndex;
            count += 1;
        }
        childOpt = tree.at(childIndex).nextSibling;
    }
    return buf[0..count];
}

test "Component children slotting: basic before + children + after" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component("slotted")({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.text("Child1");
                forbear.text("Child2");
            });
        });
        // Node creation order:
        //   0: root element
        //   1: component's inner element
        //   2: text("Before")
        //   3: text("After")
        //   4: text("Child1")
        //   5: text("Child2")
        // After slotting, element 1's children should be: Before(2), Child1(4), Child2(5), After(3)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(4, children.len);
        try std.testing.expectEqual(2, children[0]); // Before
        try std.testing.expectEqual(4, children[1]); // Child1
        try std.testing.expectEqual(5, children[2]); // Child2
        try std.testing.expectEqual(3, children[3]); // After
    });
}

test "Component children slotting: empty slot (no children passed)" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component("slotted")({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({});
        });
        // 0: root, 1: inner elem, 2: Before, 3: After
        // No children → Before(2), After(3)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(2, children.len);
        try std.testing.expectEqual(2, children[0]); // Before
        try std.testing.expectEqual(3, children[1]); // After
    });
}

test "Component children slotting: slot at beginning (no before-content)" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component("slotted")({
                forbear.element(.{})({
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.text("Child1");
            });
        });
        // 0: root, 1: inner elem, 2: After, 3: Child1
        // After slotting: Child1(3), After(2)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(2, children.len);
        try std.testing.expectEqual(3, children[0]); // Child1
        try std.testing.expectEqual(2, children[1]); // After
    });
}

test "Component children slotting: slot at end (no after-content)" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component("slotted")({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.text("Child1");
            });
        });
        // 0: root, 1: inner elem, 2: Before, 3: Child1
        // No after-content → Before(2), Child1(3)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(2, children.len);
        try std.testing.expectEqual(2, children[0]); // Before
        try std.testing.expectEqual(3, children[1]); // Child1
    });
}

test "Component children slotting: multiple instances with different children" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component("slotted")({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.text("A");
            });
            TestComponent()({
                forbear.text("B");
                forbear.text("C");
            });
        });
        // First instance: 0:root, 1:elem, 2:Before, 3:After, 4:A
        // After slotting: Before(2), A(4), After(3)
        var buf: [10]usize = undefined;
        const children1 = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(3, children1.len);
        try std.testing.expectEqual(2, children1[0]); // Before
        try std.testing.expectEqual(4, children1[1]); // A
        try std.testing.expectEqual(3, children1[2]); // After

        // Second instance: 5:elem, 6:Before, 7:After, 8:B, 9:C
        // After slotting: Before(6), B(8), C(9), After(7)
        const rootChildren = collectChildIndices(&self.nodeTree, 0, &buf);
        try std.testing.expectEqual(2, rootChildren.len);
        const secondElem = rootChildren[1];
        try std.testing.expectEqual(5, secondElem);

        const children2 = collectChildIndices(&self.nodeTree, 5, &buf);
        try std.testing.expectEqual(4, children2.len);
        try std.testing.expectEqual(6, children2[0]); // Before
        try std.testing.expectEqual(8, children2[1]); // B
        try std.testing.expectEqual(9, children2[2]); // C
        try std.testing.expectEqual(7, children2[3]); // After
    });
}

test "Component children slotting: nested slotted components" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component("test")({
                forbear.element(.{})({
                    forbear.text("before");
                    forbear.componentChildrenSlot();
                    forbear.text("after");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                TestComponent()({
                    forbear.text("Deep");
                });
            });
        });
        // Creation order:
        //   0: root element
        //   1: outer element
        //   2: "before"
        //   3: "after"
        //   4: inner element
        //   5: "before"
        //   6: "after"
        //   7: "Deep"
        // Outer element (1) children after slotting: before(2), inner-elem(4), after(3)
        var buf: [10]usize = undefined;
        const outerChildren = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(3, outerChildren.len);
        try std.testing.expectEqual(2, outerChildren[0]); // "before"
        try std.testing.expectEqual(4, outerChildren[1]); // inner element
        try std.testing.expectEqual(3, outerChildren[2]); // "after"

        // Inner element (4) children after slotting: before(5), Deep(7), after(6)
        const innerChildren = collectChildIndices(&self.nodeTree, 4, &buf);
        try std.testing.expectEqual(3, innerChildren.len);
        try std.testing.expectEqual(5, innerChildren[0]); // "before"
        try std.testing.expectEqual(7, innerChildren[1]); // "deep"
        try std.testing.expectEqual(6, innerChildren[2]); // "after"
    });
}

test "Component children slotting: parent stack stability" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component("slotted")({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            const stack = &self.frameMeta.?.nodeParentStack;
            try std.testing.expectEqual(1, stack.items.len);

            TestComponent()({
                // Stack restored to slot time: [root_elem(0), component_inner_elem(1)]
                try std.testing.expectEqual(2, stack.items.len);
                forbear.text("Child");
                try std.testing.expectEqual(2, stack.items.len);
            });

            // Stack restored to pre-slotEnd state
            try std.testing.expectEqual(1, stack.items.len);

            // Verify that subsequent elements are still added correctly
            forbear.text("AfterComponent");
        });
        var buf: [10]usize = undefined;
        // Root element (0) should have: inner element (1) + AfterComponent text node
        const rootChildren = collectChildIndices(&self.nodeTree, 0, &buf);
        try std.testing.expectEqual(2, rootChildren.len);
        try std.testing.expectEqual(1, rootChildren[0]); // component's inner element
    });
}

test "Component children slotting: element children in slot" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getContext();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component("slotted")({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try utilities.frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.element(.{})({
                    forbear.text("Nested");
                });
            });
        });
        // 0: root, 1: inner elem, 2: Before, 3: After, 4: slotted element, 5: Nested
        // Inner element (1) children: Before(2), slotted-elem(4), After(3)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(3, children.len);
        try std.testing.expectEqual(2, children[0]); // Before
        try std.testing.expectEqual(4, children[1]); // slotted element
        try std.testing.expectEqual(3, children[2]); // After

        // Slotted element (4) should contain Nested (5)
        try std.testing.expect(self.nodeTree.at(4).glyphs == null); // element, not text
        const nestedChildren = collectChildIndices(&self.nodeTree, 4, &buf);
        try std.testing.expectEqual(1, nestedChildren.len);
        try std.testing.expectEqual(5, nestedChildren[0]); // Nested
    });
}
