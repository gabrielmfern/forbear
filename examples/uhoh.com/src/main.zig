const std = @import("std");
const forbear = @import("forbear");

const spaceGroteskTtf = @embedFile("SpaceGrotesk.ttf");

fn App() !void {
    const arena = try forbear.useArena();
    const isHovering = try forbear.useState(bool, false);

    const spaceGrotesk = try forbear.useFont("SpaceGrotesk", spaceGroteskTtf);
    const comeOnImage = try forbear.useImage("come-on", @embedFile("come-on.png"), .png);

    (try forbear.element(arena, .{
        .preferredWidth = .grow,
        .direction = .topToBottom,
        .horizontalAlignment = .center,
        .font = spaceGrotesk,
        .fontWeight = 500,
        .fontSize = 12,
    }))({
        try forbear.component(arena, forbear.FpsCounter, null);
        (try forbear.element(arena, .{
            .background = .{ .image = comeOnImage },
            .preferredWidth = .{
                .fixed = 165,
            },
            .preferredHeight = .{
                .fixed = 200,
            },
        }))({});
        (try forbear.element(arena, .{
            .fontWeight = 700,
            .fontSize = 30,
            .marginBlock = .{ 10, 10 },
            .horizontalAlignment = .center,
        }))({
            try forbear.text(arena, "Dude, you’re at the bottom of our landing page.", .{});
        });
        try forbear.text(arena, "We see you’re really interested in our product. Why not give it a try?", .{});
        try forbear.text(arena, "You scrolled all the way here.", .{});
        (try forbear.element(arena, .{
            .marginBlock = .{ 20.0, 0.0 },
        }))({
            (try forbear.element(arena, .{
                .borderRadius = 6,
                .borderInlineWidth = @splat(1.5),
                .borderBlockWidth = @splat(1.5),
                .background = .{ .color = .{ 0.99, 0.98, 0.96, 1.0 } },
                .borderColor = .{ 0.0, 0.0, 0.0, 1.0 },
                .translate = .{
                    0.0,
                    try forbear.useTransition(if (isHovering.*) -4.5 else 0.0, 0.1, forbear.easeInOut),
                },
                .shadow = .{
                    .blurRadius = 0.0,
                    .spread = 0.0,
                    .color = .{ 0.0, 0.0, 0.0, 1.0 },
                    .offsetBlock = .{
                        0.0,
                        try forbear.useTransition(if (isHovering.*) 4.5 else 0.0, 0.1, forbear.easeInOut),
                    },
                    .offsetInline = @splat(0.0),
                },
                .paddingBlock = @splat(20),
                .paddingInline = @splat(36),
                .horizontalAlignment = .center,
                .verticalAlignment = .center,
                .direction = .topToBottom,
            }))({
                (try forbear.element(arena, .{ .fontSize = 18 }))({
                    try forbear.text(arena, "Come on, click on this", .{});
                });
                try forbear.text(arena, "Don't make me beg", .{});
            });
        });

        while (forbear.useNextEvent()) |event| {
            switch (event) {
                .mouseOver => {
                    isHovering.* = true;
                },
                .mouseOut => {
                    isHovering.* = false;
                },
            }
        }
    });
}

fn renderingMain(
    allocator: std.mem.Allocator,
    renderer: *forbear.Graphics.Renderer,
    window: *const forbear.Window,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        try forbear.component(arena, App, null);

        const viewportSize = renderer.viewportSize();
        const layoutBox = try forbear.layout(
            arena,
            .{
                .font = try forbear.useFont("SpaceGrotesk", spaceGroteskTtf),
                .color = .{ 0.0, 0.0, 0.0, 1.0 },
                .fontSize = 16,
                .textWrapping = .word,
                .fontWeight = 400,
                .lineHeight = 1.0,
            },
            viewportSize,
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
        );
        try renderer.drawFrame(&layoutBox, .{ 0.99, 0.98, 0.96, 1.0 }, window.dpi, window.targetFrameTimeNs());
        try forbear.update(arena, &layoutBox, viewportSize);

        forbear.resetNodeTree();
    }
    try renderer.waitIdle();
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        if (gpa.deinit() == .leak) {
            std.log.err("Memory was leaked", .{});
        }
    }

    const allocator = gpa.allocator();

    var graphics = try forbear.Graphics.init(
        allocator,
        "forbear playground",
    );
    defer graphics.deinit();

    const window = try forbear.Window.init(
        allocator,
        800,
        600,
        "uhoh.com",
        "uhoh.com",
    );
    defer window.deinit();

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();

    try forbear.init(allocator, &renderer);
    defer forbear.deinit();
    forbear.setWindowHandlers(window);

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            allocator,
            &renderer,
            window,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}
