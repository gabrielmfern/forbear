const std = @import("std");
const builtin = @import("builtin");
const forbear = @import("forbear");

const Colors = @import("colors.zig");
const Content = @import("components/content.zig").Content;
const sidebar = @import("components/sidebar.zig");
const Sidebar = sidebar.Sidebar;
const SidebarItem = sidebar.SidebarItem;
const SidebarDivider = sidebar.SidebarDivider;
const Paragraph = @import("components/paragraph.zig").Paragraph;
const Heading = @import("components/heading.zig").Heading;
const Strong = @import("components/strong.zig").Strong;
const list = @import("components/list.zig");
const List = list.List;
const ListItem = list.ListItem;

const ChapterEntry = struct {
    chapter: []const u8,
    title: []const u8,
    depth: f32 = 0.0,
};

const chapters = [_]ChapterEntry{
    .{ .chapter = "1.", .title = "Introduction" },
    .{ .chapter = "1.1.", .title = "High-level Wayland design" },
    .{ .chapter = "1.2.", .title = "Goals & target audience" },
    .{ .chapter = "1.3.", .title = "What's in the package" },
    .{ .chapter = "2.", .title = "Protocol Design" },
    .{ .chapter = "2.1.", .title = "Wire protocol basics", .depth = 1 },
    .{ .chapter = "2.2.", .title = "Interfaces, requests, events", .depth = 1 },
    .{ .chapter = "2.3.", .title = "The high-level protocol", .depth = 1 },
    .{ .chapter = "2.4.", .title = "Protocol design patterns", .depth = 1 },
    .{ .chapter = "3.", .title = "libwayland in depth" },
    .{ .chapter = "3.1.", .title = "wayland-util primitives", .depth = 1 },
    .{ .chapter = "3.2.", .title = "wayland-scanner", .depth = 1 },
    .{ .chapter = "3.3.", .title = "Proxies & resources", .depth = 1 },
    .{ .chapter = "3.4.", .title = "Interfaces & listeners", .depth = 1 },
    .{ .chapter = "4.", .title = "The Wayland display" },
    .{ .chapter = "4.1.", .title = "Creating a display", .depth = 1 },
    .{ .chapter = "4.2.", .title = "Incorporating an event loop", .depth = 1 },
    .{ .chapter = "5.", .title = "Globals & the registry" },
    .{ .chapter = "5.1.", .title = "Binding in globals", .depth = 1 },
    .{ .chapter = "5.2.", .title = "Registering globals", .depth = 1 },
    .{ .chapter = "6.", .title = "Buffers & surfaces" },
    .{ .chapter = "6.1.", .title = "Using wl_compositor", .depth = 1 },
    .{ .chapter = "6.2.", .title = "Shared memory buffers", .depth = 1 },
    .{ .chapter = "6.3.", .title = "Linux dmabuf", .depth = 1 },
    .{ .chapter = "6.4.", .title = "Surface roles", .depth = 1 },
    .{ .chapter = "7.", .title = "XDG shell basics" },
    .{ .chapter = "7.1.", .title = "XDG surfaces", .depth = 1 },
    .{ .chapter = "7.2.", .title = "Application window", .depth = 1 },
    .{ .chapter = "7.3.", .title = "Extended example code", .depth = 1 },
    .{ .chapter = "8.", .title = "Surfaces in depth" },
    .{ .chapter = "8.1.", .title = "Surface lifecycle", .depth = 1 },
    .{ .chapter = "8.2.", .title = "Frame callbacks", .depth = 1 },
    .{ .chapter = "8.3.", .title = "Damaging surfaces", .depth = 1 },
    .{ .chapter = "8.4.", .title = "Surface regions", .depth = 1 },
    .{ .chapter = "8.5.", .title = "Subsurfaces", .depth = 1 },
    .{ .chapter = "8.6.", .title = "High density surfaces (HiDPI)", .depth = 1 },
    .{ .chapter = "9.", .title = "Seats: Handling input" },
    .{ .chapter = "9.1.", .title = "Pointer input", .depth = 1 },
    .{ .chapter = "9.2.", .title = "XKB, briefly", .depth = 1 },
    .{ .chapter = "9.3.", .title = "Keyboard input", .depth = 1 },
    .{ .chapter = "9.4.", .title = "Touch input", .depth = 1 },
    .{ .chapter = "9.5.", .title = "Expanding our example code", .depth = 1 },
    .{ .chapter = "10.", .title = "XDG shell in depth" },
    .{ .chapter = "10.1.", .title = "Configuration & lifecycle", .depth = 1 },
    .{ .chapter = "10.2.", .title = "Popus & parent windows", .depth = 1 },
    .{ .chapter = "10.3.", .title = "Interactive move and resize", .depth = 1 },
    .{ .chapter = "10.4.", .title = "Positioners", .depth = 1 },
    .{ .chapter = "11.", .title = "Clipboard access" },
    .{ .chapter = "11.1.", .title = "Data offers", .depth = 1 },
    .{ .chapter = "11.2.", .title = "Drag & drop", .depth = 1 },
    .{ .chapter = "12.", .title = "Protocol extensions" },
    .{ .chapter = "12.1.", .title = "Accurate timing", .depth = 1 },
    .{ .chapter = "12.2.", .title = "Pointer constraints", .depth = 1 },
    .{ .chapter = "12.3.", .title = "Extended clipboard support", .depth = 1 },
    .{ .chapter = "12.4.", .title = "Desktop shell components", .depth = 1 },
    .{ .chapter = "12.5.", .title = "Miscellaneous extensions", .depth = 1 },
    .{ .chapter = "12.6.", .title = "Writing new extensions", .depth = 1 },
    .{ .chapter = "", .title = "Acknowledgements" },
};

fn App() !void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        const activeChapter = forbear.useState(usize, 0);

        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
            },
        })({
            forbear.FpsCounter();
            Sidebar()({
                for (chapters, 0..) |chapter, i| {
                    SidebarItem(.{
                        .active = i == activeChapter.*,
                        .key = chapter.chapter,
                        .depth = chapter.depth,
                    })({
                        if (forbear.on(.click)) {
                            activeChapter.* = i;
                        }

                        Strong()({
                            forbear.text(chapter.chapter);
                            forbear.text(" ");
                        });
                        forbear.text(chapter.title);
                    });
                }
                // TODO: add an Acknowledgments section
            });

            try Content(activeChapter);
        });
    });
}

fn renderingMain(
    allocator: std.mem.Allocator,
    io: std.Io,
    renderer: *forbear.Graphics.Renderer,
    window: *const forbear.Window,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.registerFont("Open Sans", @embedFile("OpenSans.ttf"));
    try forbear.registerFont("Source Code Pro", @embedFile("SourceCodePro.ttf"));
    try forbear.registerImage("license-badge", @embedFile("./static/license-badge.png"), .png);

    _ = io;
    // var traceFile = try std.Io.Dir.cwd().createFile(io, "layouting.log", .{});
    // defer traceFile.close(io);
    // var traceBuffer: [4096]u8 = undefined;
    // var traceWriter = traceFile.writer(io, &traceBuffer);

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        try forbear.frame(.{
            .arena = arena,
            .viewportSize = renderer.viewportSize(),
            .baseStyle = .{
                .font = try forbear.useFont("Open Sans"),
                .color = Colors.text,
                .fontSize = 16.0,
                .textWrapping = .word,
                .fontWeight = 400,
                .cursor = .default,
                .lineHeight = 1.0,
                .blendMode = .normal,
            },
        })({
            try App();

            const rootTree = try forbear.layout();
            // try rootTree.dump(&traceWriter.interface);

            try renderer.drawFrame(arena, rootTree, Colors.page, window.targetFrameTimeNs());
            try forbear.update();
        });
    }
    try renderer.waitIdle();
}

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    const allocator, const is_debug = switch (builtin.mode) {
        .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
        .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
    };
    defer if (is_debug) {
        if (debug_allocator.deinit() == .leak) {
            std.log.err("Memory was leaked", .{});
        }
    };

    var threaded = std.Io.Threaded.init(allocator, .{});
    defer threaded.deinit();
    const io = threaded.io();

    var graphics = try forbear.Graphics.init(
        allocator,
        "forbear playground",
    );
    defer graphics.deinit();

    const window = try forbear.Window.init(
        allocator,
        1280,
        800,
        "wayland-book.com",
        "wayland-book.com",
    );
    defer window.deinit();

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();

    try forbear.init(allocator, io, &renderer);
    defer forbear.deinit();

    forbear.setWindowHandlers(window);

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            allocator,
            io,
            &renderer,
            window,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}
