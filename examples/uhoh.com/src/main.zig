const std = @import("std");
const Forbear = @import("forbear");

fn renderingMain(
    renderer: *Forbear.Graphics.Renderer,
    forbearContext: *Forbear,
    window: *const Forbear.Window,
    allocator: std.mem.Allocator,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    const spaceGroteskMedium = try Forbear.Font.init("SpaceGrotesk-Medium", @embedFile("SpaceGrotesk-Medium.ttf"));
    const spaceGroteskBold = try Forbear.Font.init("SpaceGrotesk-Bold", @embedFile("SpaceGrotesk-Bold.ttf"));

    const comeOnImage = try Forbear.Image.init(@embedFile("come-on.png"), .png, renderer);
    defer comeOnImage.deinit(renderer);

    var hoveringClickMe = false;

    while (window.running) {
        const EventData = struct {
            hoveringClickMe: *bool,
        };
        var eventData = EventData{
            .hoveringClickMe = &hoveringClickMe,
        };
        const node = Forbear.div(.{
            .style = .{
                .preferredWidth = .grow,
                .direction = .topToBottom,
                .horizontalAlignment = .center,
                .fontSize = 12,
            },
            .children = try Forbear.children(.{
                Forbear.div(.{
                    .style = .{
                        .background = .{ .image = &comeOnImage },
                        .preferredWidth = .{
                            .fixed = 180,
                        },
                        .preferredHeight = .{
                            .fixed = 200,
                        },
                    },
                }),
                Forbear.div(.{
                    .style = .{
                        .font = spaceGroteskBold,
                        .fontSize = 30,
                        .marginBlock = .{ 10, 10 },
                    },
                    .children = try Forbear.children(.{
                        "Dude, you’re at the bottom of our landing page.",
                    }, arena),
                }),
                "Just get the free trial already if you’re that interested.",
                "You scrolled all the way here.",
                Forbear.div(.{
                    .style = .{
                        .borderRadius = 6,
                        .borderInlineWidth = @splat(1.5),
                        .borderBlockWidth = @splat(1.5),
                        .marginBlock = .{ 20.0, 0.0 },
                        .background = .{ .color = .{ 0.99, 0.98, 0.96, 1.0 } },
                        .borderColor = .{ 0.0, 0.0, 0.0, 1.0 },
                        .shadow = .{
                            .blurRadius = 0.0,
                            .spread = 0.0,
                            .color = .{ 0.0, 0.0, 0.0, 1.0 },
                            .offsetBlock = if (hoveringClickMe) .{ 0.0, 6.0 } else .{ 0.0, 0.0 },
                            .offsetInline = @splat(0.0),
                        },
                        .paddingBlock = @splat(20),
                        .paddingInline = @splat(36),
                        .horizontalAlignment = .center,
                        .verticalAlignment = .center,
                        .direction = .topToBottom,
                    },
                    .handlers = .{
                        .onMouseOver = .{
                            .handler = &(struct {
                                pub fn handler(
                                    mousePosition: @Vector(2, f32),
                                    data: ?*anyopaque,
                                ) !void {
                                    std.log.debug("mouse over", .{});
                                    _ = mousePosition;
                                    const eventDataLocal: *EventData = @ptrCast(@alignCast(data.?));
                                    eventDataLocal.hoveringClickMe.* = true;
                                }
                            }).handler,
                            .data = &eventData,
                        },
                        .onMouseOut = .{
                            .handler = &(struct {
                                pub fn handler(
                                    mousePosition: @Vector(2, f32),
                                    data: ?*anyopaque,
                                ) !void {
                                    std.log.debug("mouse out", .{});
                                    _ = mousePosition;
                                    const eventDataLocal: *EventData = @ptrCast(@alignCast(data.?));
                                    eventDataLocal.hoveringClickMe.* = false;
                                }
                            }).handler,
                            .data = &eventData,
                        },
                    },
                    .children = try Forbear.children(.{
                        Forbear.div(.{
                            .style = .{
                                .fontSize = 18,
                            },
                            .children = try Forbear.children(.{
                                "Come on, click on this",
                            }, arena),
                        }),
                        "Don't make me beg",
                    }, arena),
                }),
            }, arena),
        });
        const layoutBox = try Forbear.layout(
            node,
            .{
                .font = spaceGroteskMedium,
                .color = .{ 0.0, 0.0, 0.0, 1.0 },
                .fontSize = 16,
                .lineHeight = 1.0,
            },
            renderer.viewportSize(),
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
            arena,
        );
        try renderer.drawFrame(&layoutBox, .{ 0.99, 0.98, 0.96, 1.0 }, window.dpi, window.targetFrameTimeNs());
        try forbearContext.update(&layoutBox, arena);
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

    var graphics = try Forbear.Graphics.init(
        "forbear playground",
        allocator,
    );
    defer graphics.deinit();

    const window = try Forbear.Window.init(
        800,
        600,
        "uhoh.com",
        "uhoh.com",
        allocator,
    );
    defer window.deinit();

    var forbearContext = try Forbear.init();
    defer forbearContext.deinit();
    forbearContext.setHandlers(window);

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();
    window.setResizeHandler(handleResize, @ptrCast(@alignCast(&renderer)));

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            &renderer,
            &forbearContext,
            window,
            allocator,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}

fn handleResize(window: *Forbear.Window, width: u32, height: u32, dpi: [2]u32, data: *anyopaque) void {
    _ = window;
    _ = dpi;
    const renderer: *Forbear.Graphics.Renderer = @ptrCast(@alignCast(data));
    renderer.handleResize(width, height) catch |err| {
        std.log.err("Renderer could not handle window resize {}", .{err});
    };
}
