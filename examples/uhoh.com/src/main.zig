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
            },
            .children = try forbear.children(.{
                forbear.div(.{
                    .style = .{
                        .background = .{ .image = &comeOnImage },
                        .preferredWidth = .{
                            .fixed = 200,
                        },
                        .preferredHeight = .{
                            .fixed = 200,
                        },
                    },
                }),
                forbear.div(.{
                    .style = .{
                        .font = spaceGroteskBold,
                        .fontSize = 24,
                    },
                    .children = try forbear.children(.{
                        "Dude, you’re at the bottom of our landing page.",
                    }, arena),
                }),
                "Just get the free trial already if you’re that interested.",
                "You scrolled all the way here.",
            }, arena),
        });
        const layoutBox = try forbear.layout(
            node,
            .{ .font = spaceGroteskMedium, .color = .{ 0.0, 0.0, 0.0, 1.0 }, .fontSize = 16, .lineHeight = 1.0 },
            renderer.viewportSize(),
            .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
            arena,
        );
        try renderer.drawFrame(&layoutBox, .{ 1.0, 1.0, 1.0, 1.0 });
    }
}
