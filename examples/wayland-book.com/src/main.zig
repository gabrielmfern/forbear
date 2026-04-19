const std = @import("std");
const forbear = @import("forbear");

const Colors = @import("colors.zig");
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
    .{ .chapter = "", .title = "Introduction" },
    .{ .chapter = "1.", .title = "Protocol Design" },
    .{ .chapter = "1.1.", .title = "Wire protocol basics", .depth = 1 },
    .{ .chapter = "1.2.", .title = "Interfaces, requests, and events", .depth = 1 },
    .{ .chapter = "1.3.", .title = "High-level protocol overview", .depth = 1 },
    .{ .chapter = "1.4.", .title = "Wayland object lifetime", .depth = 1 },
    .{ .chapter = "2.", .title = "Libwayland basics" },
    .{ .chapter = "2.1.", .title = "Wayland protocol & libwayland", .depth = 1 },
    .{ .chapter = "2.2.", .title = "Displays and wl_display", .depth = 1 },
    .{ .chapter = "2.3.", .title = "Globals & the registry", .depth = 1 },
    .{ .chapter = "3.", .title = "Surfaces in depth" },
    .{ .chapter = "3.1.", .title = "Surface basics", .depth = 1 },
    .{ .chapter = "3.2.", .title = "Surface regions", .depth = 1 },
    .{ .chapter = "3.3.", .title = "Compositing and subsurfaces", .depth = 1 },
    .{ .chapter = "4.", .title = "Buffers & surfaces" },
    .{ .chapter = "4.1.", .title = "Shared memory buffers", .depth = 1 },
    .{ .chapter = "4.2.", .title = "DMA-BUF", .depth = 1 },
    .{ .chapter = "5.", .title = "XDG shell basics" },
    .{ .chapter = "5.1.", .title = "XDG surfaces", .depth = 1 },
    .{ .chapter = "5.2.", .title = "Application windows", .depth = 1 },
    .{ .chapter = "5.3.", .title = "Example code", .depth = 1 },
    .{ .chapter = "6.", .title = "Seat: Handling input" },
    .{ .chapter = "6.1.", .title = "Pointer input", .depth = 1 },
    .{ .chapter = "6.2.", .title = "Keyboard input", .depth = 1 },
    .{ .chapter = "6.3.", .title = "Touch input", .depth = 1 },
    .{ .chapter = "6.4.", .title = "Example code", .depth = 1 },
    .{ .chapter = "7.", .title = "Beyond the basics" },
    .{ .chapter = "8.", .title = "XDG shell, in depth" },
    .{ .chapter = "9.", .title = "Clipboard & DnD" },
    .{ .chapter = "10.", .title = "High-DPI support" },
};

fn Topbar() void {
    forbear.element(.{
        .width = .grow,
        .direction = .horizontal,
        .xJustification = .center,
        .yJustification = .center,
        .padding = forbear.Padding.block(12.0).withInLine(24.0),
    })({
        Heading(1)({
            forbear.text("The Wayland Protocol");
        });
        // TODO: add a printer icon SVG
    });
}

fn TodoList() void {
    forbear.element(.{
        .width = .grow,
        .direction = .vertical,
        .margin = forbear.Margin.block(6.0).withBottom(18.0),
    })({
        Heading(1)({
            forbear.text("TODO");
        });
        List()({
            ListItem()({
                forbear.text("Expand on resource lifetimes and avoiding race conditions in chapter 2.4");
            });
            ListItem()({
                forbear.text("Move linux-dmabuf details to the appendix, add note about wl_drm & Mesa");
            });
            ListItem()({
                forbear.text("Rewrite the introduction text");
            });
            ListItem()({
                forbear.text("Add example code for interactive move, to demonstrate the use of serials");
            });
            ListItem()({
                forbear.text("Prepare PDFs and EPUBs");
            });
        });
    });
}

fn LicenseBadge() void {
    forbear.element(.{
        .padding = forbear.Padding.block(4.5).withInLine(10.5),
        .background = .{ .color = .{ 0.93, 0.93, 0.94, 1.0 } },
        .borderRadius = 3.0,
        .fontSize = 10.0,
        .fontWeight = 600,
        .margin = forbear.Margin.top(6.0).withBottom(0.0),
    })({
        // TODO: insert license badge image here
    });
}

fn Content() void {
    forbear.component("content")({
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .vertical,
            .xJustification = .center,
            .yJustification = .start,
        })({
            Topbar();

            forbear.element(.{
                .width = .grow,
                .direction = .vertical,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.block(36.0).withInLine(48.0),
                .maxWidth = 820.0,
            })({
                Heading(1)({
                    forbear.text("Introduction");
                });

                Paragraph()({
                   forbear.text("Wayland is the next-generation display server for Unix-like systems, designed and built by the alumni of the venerable Xorg server, and is the best way to get your application windows onto your user's screens. Readers who have worked with X11 in the past will be pleasantly surprised by Wayland's improvements, and those who are new to graphics on Unix will find it a flexible and powerful system for building graphical applications and desktops.");
                });

                Paragraph()({
                    forbear.text("This book will help you establish a firm understanding of the concepts, design, and implementation of Wayland, and equip you with the tools to build your own Wayland client and server applications. Over the course of your reading, we'll build a mental model of Wayland and establish the rationale that went into its design. Within these pages you should find many \"aha!\" moments as the intuitive design choices of Wayland become clear, which should help to keep the pages turning. Welcome to the future of open source graphics!");
                });

                TodoList();

                Heading(2)({
                    forbear.text("About the book");
                });
                Paragraph()({
                    forbear.text("This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License. The source code is available at git.sr.ht/~sircmpwn/wayland-book.");
                });
                LicenseBadge();

                Heading(2)({
                    forbear.text("About the author");
                });
                Paragraph()({
                    forbear.text("In the words of Preston Carpenter, a close collaborator of Drew's:");
                });

                Paragraph()({
                    forbear.text("Drew DeVault got his start in the Wayland world by building sway, a clone of the popular tiling window manager i3. It is now the most popular tiling Wayland compositor by any measure: users, commit count, and influence. Following its success, Drew gave back to the Wayland community by starting wlroots: unopinionated, composable modules for building a Wayland compositor. Today it is the foundation for dozens of independent compositors, and Drew is one of the foremost experts in Wayland.");
                });
            });
        });
    });
}

fn App() !void {
    forbear.component("app")({
        const activeChapter = forbear.useState(usize, 0);

        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .direction = .horizontal,
            .xJustification = .start,
            .yJustification = .start,
            .font = try forbear.useFont("Inter"),
            .fontWeight = 400,
            .fontSize = 12.0,
            .color = Colors.text,
        })({
            forbear.FpsCounter();
            Sidebar()({
                for (chapters, 0..) |chapter, i| {
                    SidebarItem(.{
                        .active = i == activeChapter.*,
                        .depth = chapter.depth,
                    })({
                        Strong()({
                            forbear.text(chapter.chapter);
                            forbear.text(" ");
                        });
                        forbear.text(chapter.title);
                    });
                }
                // TODO: add an Acknowledgments section
            });

            Content();
        });
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

    try forbear.registerFont("Inter", @embedFile("Inter.ttf"));

    var traceFile = try std.fs.cwd().createFile("layouting.log", .{});
    defer traceFile.close();
    var traceBuffer: [4096]u8 = undefined;
    var traceWriter = traceFile.writer(&traceBuffer);

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        try forbear.frame(.{
            .arena = arena,
            .dpi = .{ @floatFromInt(window.dpi[0]), @floatFromInt(window.dpi[1]) },
            .viewportSize = renderer.viewportSize(),
            .baseStyle = .{
                .font = try forbear.useFont("Inter"),
                .color = Colors.text,
                .fontSize = 12.0,
                .textWrapping = .word,
                .fontWeight = 400,
                .cursor = .default,
                .lineHeight = 1.5,
                .blendMode = .normal,
            },
        })({
            try App();

            const rootTree = try forbear.layout();
            try rootTree.dump(&traceWriter.interface);

            try renderer.drawFrame(arena, rootTree, Colors.page, window.dpi, window.targetFrameTimeNs());
            try forbear.update();
        });
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
        1280,
        800,
        "wayland-book.com",
        "wayland-book.com",
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
