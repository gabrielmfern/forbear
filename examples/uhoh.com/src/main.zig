const std = @import("std");
const forbear = @import("forbear");

const spaceGroteskTtf = @embedFile("SpaceGrotesk.ttf");

fn App() !forbear.Node {
    const arena = try forbear.useArena();
    const isHovering = try forbear.useState(bool, false);

    const spaceGrotesk = try forbear.useFont("SpaceGrotesk", spaceGroteskTtf);
    const comeOnImage = try forbear.useImage("come-on", @embedFile("come-on.png"), .png);

    return forbear.div(.{ .style = .{
        .preferredWidth = .grow,
        .direction = .topToBottom,
        .horizontalAlignment = .center,
        .font = spaceGrotesk,
        .fontWeight = 500,
        .fontSize = 12,
    }, .children = try forbear.children(arena, .{
        forbear.component(forbear.FpsCounter, null, arena),
        forbear.div(.{
            .style = .{
                .background = .{ .image = comeOnImage },
                .preferredWidth = .{
                    .fixed = 165,
                },
                .preferredHeight = .{
                    .fixed = 200,
                },
            },
        }),
        forbear.div(.{ .style = .{
            .fontWeight = 700,
            .fontSize = 30,
            .marginBlock = .{ 10, 10 },
        }, .children = try forbear.children(arena, .{
            "Dude, you’re at the bottom of our landing page.",
        }) }),
        "Just get the free trial already if you’re that interested.",
        "You scrolled all the way here.",
        forbear.div(.{ .style = .{
            .borderRadius = 6,
            .borderInlineWidth = @splat(1.5),
            .borderBlockWidth = @splat(1.5),
            .marginBlock = .{ 20.0, 0.0 },
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
        }, .handlers = .{
            .onMouseOver = try forbear.eventHandler(
                arena,
                isHovering,
                (struct {
                    fn handler(_: *const forbear.LayoutBox, hovering: *bool) anyerror!void {
                        hovering.* = true;
                    }
                }).handler,
            ),
            .onMouseOut = try forbear.eventHandler(
                arena,
                isHovering,
                (struct {
                    fn handler(_: *const forbear.LayoutBox, hovering: *bool) anyerror!void {
                        hovering.* = false;
                    }
                }).handler,
            ),
        }, .children = try forbear.children(arena, .{
            forbear.div(.{ .style = .{
                .fontSize = 18,
            }, .children = try forbear.children(arena, .{
                "Come on, click on this",
            }) }),
            "Don't make me beg",
        }) }),
    }) });
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

        const treeNode = try forbear.resolve(try forbear.component(
            App,
            null,
            arena,
        ), arena);
        const viewportSize = renderer.viewportSize();
        const layoutBox = try forbear.layout(
            arena,
            treeNode,
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
        try forbear.update(&layoutBox, viewportSize, arena);
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

