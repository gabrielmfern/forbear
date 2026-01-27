const std = @import("std");
const forbear = @import("forbear");

const AppProps = struct {
    spaceGrotesk: forbear.Font,
    comeOnImage: *const forbear.Image,
};

fn App(props: AppProps) !forbear.Node {
    const arena = try forbear.useArena();
    const isHovering = try forbear.useState(bool, false);

    return forbear.div(.{ .style = .{
        .preferredWidth = .grow,
        .direction = .topToBottom,
        .horizontalAlignment = .center,
        .fontWeight = 500,
        .fontSize = 12,
    }, .children = try forbear.children(.{
        forbear.div(.{
            .style = .{
                .background = .{ .image = props.comeOnImage },
                .preferredWidth = .{
                    .fixed = 165,
                },
                .preferredHeight = .{
                    .fixed = 200,
                },
            },
        }),
        forbear.div(.{ .style = .{
            .font = props.spaceGrotesk,
            .fontWeight = 700,
            .fontSize = 30,
            .marginBlock = .{ 10, 10 },
        }, .children = try forbear.children(.{
            "Dude, you’re at the bottom of our landing page.",
        }, arena) }),
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
                isHovering,
                (struct {
                    fn handler(_: *const forbear.LayoutBox, hovering: *bool) anyerror!void {
                        hovering.* = true;
                    }
                }).handler,
                arena,
            ),
            .onMouseOut = try forbear.eventHandler(
                isHovering,
                (struct {
                    fn handler(_: *const forbear.LayoutBox, hovering: *bool) anyerror!void {
                        hovering.* = false;
                    }
                }).handler,
                arena,
            ),
        }, .children = try forbear.children(.{
            forbear.div(.{ .style = .{
                .fontSize = 18,
            }, .children = try forbear.children(.{
                "Come on, click on this",
            }, arena) }),
            "Don't make me beg",
        }, arena) }),
    }, arena) });
}

fn renderingMain(
    renderer: *forbear.Graphics.Renderer,
    window: *const forbear.Window,
    allocator: std.mem.Allocator,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    const spaceGrotesk = try forbear.Font.init("SpaceGrotesk", @embedFile("SpaceGrotesk.ttf"));
    defer spaceGrotesk.deinit();

    const comeOnImage = try forbear.Image.init(@embedFile("come-on.png"), .png, renderer);
    defer comeOnImage.deinit(renderer);

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        const treeNode = try forbear.resolve(try forbear.component(
            App,
            AppProps{ .comeOnImage = &comeOnImage, .spaceGrotesk = spaceGrotesk },
            arena,
        ), arena);
        const layoutBox = try forbear.layout(
            treeNode,
            .{
                .font = spaceGrotesk,
                .color = .{ 0.0, 0.0, 0.0, 1.0 },
                .fontSize = 16,
                .fontWeight = 400,
                .lineHeight = 1.0,
            },
            renderer.viewportSize(),
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
            arena,
        );
        try renderer.drawFrame(&layoutBox, .{ 0.99, 0.98, 0.96, 1.0 }, window.dpi, window.targetFrameTimeNs());
        try forbear.update(&layoutBox, arena);
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
        "forbear playground",
        allocator,
    );
    defer graphics.deinit();

    const window = try forbear.Window.init(
        800,
        600,
        "uhoh.com",
        "uhoh.com",
        allocator,
    );
    defer window.deinit();

    try forbear.init(allocator);
    defer forbear.deinit();
    forbear.setWindowHandlers(window);

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();
    window.setResizeHandler(handleResize, @ptrCast(@alignCast(&renderer)));

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            &renderer,
            window,
            allocator,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}

fn handleResize(window: *forbear.Window, width: u32, height: u32, dpi: [2]u32, data: *anyopaque) void {
    _ = window;
    _ = dpi;
    const renderer: *forbear.Graphics.Renderer = @ptrCast(@alignCast(data));
    renderer.handleResize(width, height) catch |err| {
        std.log.err("Renderer could not handle window resize {}", .{err});
    };
}
