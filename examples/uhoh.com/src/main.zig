const std = @import("std");
const builtin = @import("builtin");

const forbear = @import("forbear");

const colors = @import("colors.zig");
const Benefits = @import("components/benefits.zig").Benefits;
const BottomCta = @import("components/bottom_cta.zig").BottomCta;
const Footer = @import("components/footer.zig").Footer;
const Header = @import("components/header.zig").Header;
const Hero = @import("components/hero.zig").Hero;
const JonQuote = @import("components/jon_quote.zig").JonQuote;
const Offerings = @import("components/offerings.zig").Offerings;
const Partners = @import("components/partners.zig").Partners;
const Problems = @import("components/problems.zig").Problems;
const Solution = @import("components/solution.zig").Solution;
const Statements = @import("components/statements.zig").Statements;
const TestimonialsSection = @import("components/testimonials_section.zig").TestimonialsSection;

const rainbowBar = [_]forbear.GradientStop{
    .{ .color = forbear.hex("ff6b9d"), .position = 0.0 },
    .{ .color = forbear.hex("ffb066"), .position = 0.18 },
    .{ .color = forbear.hex("fff066"), .position = 0.36 },
    .{ .color = forbear.hex("9bf088"), .position = 0.54 },
    .{ .color = forbear.hex("6bc7ff"), .position = 0.72 },
    .{ .color = forbear.hex("c69bff"), .position = 1.0 },
};

fn App() !void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        const viewportSize = forbear.useViewportSize();
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .fixed = viewportSize[1] },
                .direction = .vertical,
                .xJustification = .center,
                .yJustification = .start,
            },
        })({
            forbear.ScrollBar(forbear.useScrolling());

            forbear.FpsCounter();

            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .background = .{ .gradient = &rainbowBar },
                    .padding = .all(15.0),
                    .xJustification = .center,
                    .yJustification = .center,
                    .fontWeight = 500,
                },
            })({
                forbear.text("→ Book a 15 minute meeting today.");
            });

            try Header();
            try Hero();
            try Statements();
            try Problems();
            TestimonialsSection();
            try Partners();
            try Solution();
            try Offerings();
            try JonQuote();
            try Benefits();
            try BottomCta();
            try Footer();
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

    try forbear.registerFont("SpaceGrotesk", @embedFile("SpaceGrotesk.ttf"));

    try forbear.registerImage("uhoh-logo", @embedFile("static/uhoh-logo.png"), .png);
    try forbear.registerImage("uhoh-hero", @embedFile("static/uhoh-hero.png"), .png);
    try forbear.registerImage("uhoh-check", @embedFile("static/uhoh-check.png"), .png);
    try forbear.registerImage("uhoh-problem", @embedFile("static/uhoh-problem.png"), .png);
    try forbear.registerImage("uhoh-x-red", @embedFile("static/uhoh-x-red.png"), .png);
    try forbear.registerImage("uhoh-testimonial-1", @embedFile("static/uhoh-testimonial-1.png"), .png);
    try forbear.registerImage("uhoh-testimonial-2", @embedFile("static/uhoh-testimonial-2.png"), .png);
    try forbear.registerImage("uhoh-testimonial-moses", @embedFile("static/uhoh-testimonial-moses.png"), .png);
    try forbear.registerImage("uhoh-testimonial-alex", @embedFile("static/uhoh-testimonial-alex.png"), .png);
    try forbear.registerImage("uhoh-testimonial-stephanie", @embedFile("static/uhoh-testimonial-stephanie.png"), .png);
    try forbear.registerImage("uhoh-testimonial-enoch", @embedFile("static/uhoh-testimonial-enoch.png"), .png);
    try forbear.registerImage("uhoh-partner-badge", @embedFile("static/uhoh-partner-badge.png"), .png);
    try forbear.registerImage("uhoh-google-logo", @embedFile("static/uhoh-google-logo.png"), .png);
    try forbear.registerImage("uhoh-microsoft-logo", @embedFile("static/uhoh-microsoft-logo.png"), .png);
    try forbear.registerImage("uhoh-partner-logo", @embedFile("static/uhoh-partner-logo.png"), .png);
    try forbear.registerImage("uhoh-zoho-logo", @embedFile("static/uhoh-zoho-logo.png"), .png);
    try forbear.registerImage("uhoh-solution", @embedFile("static/uhoh-solution.png"), .png);
    try forbear.registerImage("uhoh-offer-46", @embedFile("static/uhoh-offer-46.png"), .png);
    try forbear.registerImage("uhoh-offer-47", @embedFile("static/uhoh-offer-47.png"), .png);
    try forbear.registerImage("uhoh-offer-50", @embedFile("static/uhoh-offer-50.png"), .png);
    try forbear.registerImage("uhoh-offer-49", @embedFile("static/uhoh-offer-49.png"), .png);
    try forbear.registerImage("uhoh-offer-51", @embedFile("static/uhoh-offer-51.png"), .png);
    try forbear.registerImage("uhoh-offer-53", @embedFile("static/uhoh-offer-53.png"), .png);
    try forbear.registerImage("uhoh-jon-avatar", @embedFile("static/uhoh-jon-avatar.png"), .png);
    try forbear.registerImage("uhoh-how-it-works", @embedFile("static/uhoh-how-it-works.png"), .png);
    try forbear.registerImage("uhoh-group-21", @embedFile("static/uhoh-group-21.png"), .png);
    try forbear.registerImage("uhoh-failure", @embedFile("static/uhoh-failure.png"), .png);
    try forbear.registerImage("uhoh-bottom-cta", @embedFile("static/uhoh-bottom-cta.png"), .png);

    var traceFile = try std.Io.Dir.cwd().createFile(io, "layouting.log", .{});
    defer traceFile.close(io);
    var traceBuffer: [4096]u8 = undefined;
    var traceWriter = traceFile.writer(io, &traceBuffer);

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        try forbear.frame(.{
            .arena = arena,
            .viewportSize = renderer.viewportSize(),
            .baseStyle = .{
                .font = try forbear.useFont("SpaceGrotesk"),
                .color = .{ 0.0, 0.0, 0.0, 1.0 },
                .fontSize = 16,
                .textWrapping = .word,
                .fontWeight = 400,
                .cursor = .default,
                .lineHeight = 1.0,
                .blendMode = .normal,
            },
        })({
            try App();

            const rootTree = try forbear.layout();
            try rootTree.dump(&traceWriter.interface);

            try renderer.drawFrame(arena, rootTree, colors.background, window.targetFrameTimeNs());
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
        720,
        "uhoh.com",
        "uhoh.com",
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
