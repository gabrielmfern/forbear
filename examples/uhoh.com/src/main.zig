const std = @import("std");
const forbear = @import("forbear");

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

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();
    renderer.setupResizingHandler(window);

    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    const spaceGroteskMedium = try forbear.Font.init("SpaceGrotesk-Medium", @embedFile("SpaceGrotesk-Medium.ttf"));
    const spaceGroteskBold = try forbear.Font.init("SpaceGrotesk-Bold", @embedFile("SpaceGrotesk-Bold.ttf"));

    const comeOnImage = try forbear.Image.init(@embedFile("come-on.png"), .png, &renderer);
    defer comeOnImage.deinit(&renderer);

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        try window.handleEvents();
        const node = forbear.div(.{
            .style = .{
                .preferredWidth = .grow,
                .direction = .topToBottom,
                .horizontalAlignment = .center,
                .fontSize = 12,
            },
            .children = try forbear.children(.{
                forbear.div(.{
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
                forbear.div(.{
                    .style = .{
                        .font = spaceGroteskBold,
                        .fontSize = 30,
                        .marginBlock = .{ 10, 10 },
                    },
                    .children = try forbear.children(.{
                        "Dude, you’re at the bottom of our landing page.",
                    }, arena),
                }),
                "Just get the free trial already if you’re that interested.",
                "You scrolled all the way here.",
                forbear.div(.{
                    .style = .{
                        .borderRadius = 6,
                        .borderInlineWidth = @splat(1.5),
                        .borderBlockWidth = @splat(1.5),
                        .marginBlock = .{ 20.0, 0.0 },
                        .borderColor = .{ 0.0, 0.0, 0.0, 1.0 },
                        .paddingBlock = @splat(20),
                        .paddingInline = @splat(36),
                        .horizontalAlignment = .center,
                        .verticalAlignment = .center,
                        .direction = .topToBottom,
                    },
                    .children = try forbear.children(.{
                        forbear.div(.{
                            .style = .{
                                .fontSize = 18,
                            },
                            .children = try forbear.children(.{
                                "Come on, click on this",
                            }, arena),
                        }),
                        "Don't make me beg",
                    }, arena),
                }),
            }, arena),
        });
        const layoutBox = try forbear.layout(
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
        try renderer.drawFrame(&layoutBox, .{ 0.99, 0.98, 0.96, 1.0 });
    }
    try renderer.waitIdle();
}
