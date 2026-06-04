const std = @import("std");
const forbear = @import("forbear");

const unicode_blocks = [_][]const u8{
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
    "!@#$%^&*()_+-=[]{}|;':\",./<>?~`",
    "\u{00C0}\u{00C1}\u{00C2}\u{00C3}\u{00C4}\u{00C5}\u{00C6}\u{00C7}\u{00C8}\u{00C9}\u{00CA}\u{00CB}\u{00CC}\u{00CD}\u{00CE}\u{00CF}",
    "\u{00D0}\u{00D1}\u{00D2}\u{00D3}\u{00D4}\u{00D5}\u{00D6}\u{00D8}\u{00D9}\u{00DA}\u{00DB}\u{00DC}\u{00DD}\u{00DE}\u{00DF}",
    "\u{00E0}\u{00E1}\u{00E2}\u{00E3}\u{00E4}\u{00E5}\u{00E6}\u{00E7}\u{00E8}\u{00E9}\u{00EA}\u{00EB}\u{00EC}\u{00ED}\u{00EE}\u{00EF}",
    "\u{0100}\u{0101}\u{0102}\u{0103}\u{0104}\u{0105}\u{0106}\u{0107}\u{0108}\u{0109}\u{010A}\u{010B}\u{010C}\u{010D}\u{010E}\u{010F}",
    "\u{0110}\u{0111}\u{0112}\u{0113}\u{0114}\u{0115}\u{0116}\u{0117}\u{0118}\u{0119}\u{011A}\u{011B}\u{011C}\u{011D}\u{011E}\u{011F}",
    "\u{0391}\u{0392}\u{0393}\u{0394}\u{0395}\u{0396}\u{0397}\u{0398}\u{0399}\u{039A}\u{039B}\u{039C}\u{039D}\u{039E}\u{039F}\u{03A0}",
    "\u{03B1}\u{03B2}\u{03B3}\u{03B4}\u{03B5}\u{03B6}\u{03B7}\u{03B8}\u{03B9}\u{03BA}\u{03BB}\u{03BC}\u{03BD}\u{03BE}\u{03BF}\u{03C0}",
    "\u{0410}\u{0411}\u{0412}\u{0413}\u{0414}\u{0415}\u{0416}\u{0417}\u{0418}\u{0419}\u{041A}\u{041B}\u{041C}\u{041D}\u{041E}\u{041F}",
    "\u{0430}\u{0431}\u{0432}\u{0433}\u{0434}\u{0435}\u{0436}\u{0437}\u{0438}\u{0439}\u{043A}\u{043B}\u{043C}\u{043D}\u{043E}\u{043F}",
    "\u{2200}\u{2201}\u{2202}\u{2203}\u{2204}\u{2205}\u{2206}\u{2207}\u{2208}\u{2209}\u{220A}\u{220B}\u{220C}\u{220D}\u{220E}\u{220F}",
    "\u{2190}\u{2191}\u{2192}\u{2193}\u{2194}\u{2195}\u{2196}\u{2197}\u{2198}\u{2199}\u{219A}\u{219B}\u{219C}\u{219D}\u{219E}\u{219F}",
    "\u{2580}\u{2581}\u{2582}\u{2583}\u{2584}\u{2585}\u{2586}\u{2587}\u{2588}\u{2589}\u{258A}\u{258B}\u{258C}\u{258D}\u{258E}\u{258F}",
    "\u{00A1}\u{00A2}\u{00A3}\u{00A4}\u{00A5}\u{00A6}\u{00A7}\u{00A8}\u{00A9}\u{00AA}\u{00AB}\u{00AC}\u{00AD}\u{00AE}\u{00AF}",
    "\u{2460}\u{2461}\u{2462}\u{2463}\u{2464}\u{2465}\u{2466}\u{2467}\u{2468}\u{2469}\u{246A}\u{246B}\u{246C}\u{246D}\u{246E}\u{246F}",
};

var frameCount: u64 = 0;

const FrameBenchmark = struct {
    const max_samples = 16384;

    frameTimes: [max_samples]f64 = undefined,
    count: usize = 0,
    totalElapsed: f64 = 0,

    fn recordFrame(self: *@This(), dt: f64) void {
        if (self.count < max_samples) {
            self.frameTimes[self.count] = dt;
        }
        self.count += 1;
        self.totalElapsed += dt;
    }

    fn report(self: *@This()) void {
        const n = @min(self.count, max_samples);
        if (n == 0) return;

        const times = self.frameTimes[0..n];

        var min: f64 = times[0];
        var max: f64 = times[0];
        var sum: f64 = 0;
        for (times) |t| {
            if (t < min) min = t;
            if (t > max) max = t;
            sum += t;
        }
        const avg = sum / @as(f64, @floatFromInt(n));

        std.mem.sort(f64, times, {}, std.sort.asc(f64));
        const p50 = times[n / 2];
        const p95 = times[n - 1 - n / 20];
        const p99 = times[n - 1 - n / 100];

        const avgFps = if (avg > 0) 1000.0 / avg else 0;

        var stutterCount: usize = 0;
        const stutterThreshold = p50 * 2.0;
        for (times) |t| {
            if (t > stutterThreshold) stutterCount += 1;
        }

        std.debug.print(
            \\
            \\--- Frame Benchmark Report ---
            \\  frames recorded: {d}{s}
            \\  total time:      {d:.2}s
            \\  avg FPS:         {d:.1}
            \\
            \\  frame time (ms):
            \\    min:  {d:.2}
            \\    avg:  {d:.2}
            \\    max:  {d:.2}
            \\    p50:  {d:.2}
            \\    p95:  {d:.2}
            \\    p99:  {d:.2}
            \\
            \\  stutters (>{d:.2}ms): {d} ({d:.1}%)
            \\-----------------------------
            \\
        , .{
            n,
            if (self.count > max_samples) @as([]const u8, " (capped)") else "",
            self.totalElapsed / 1000.0,
            avgFps,
            min,
            avg,
            max,
            p50,
            p95,
            p99,
            stutterThreshold,
            stutterCount,
            @as(f64, @floatFromInt(stutterCount)) / @as(f64, @floatFromInt(n)) * 100.0,
        });
    }
};

var benchmark = FrameBenchmark{};

fn TextLine(key: []const u8, text: []const u8, fontSize: f32) void {
    forbear.element(.{
        .key = key,
        .style = .{
            .width = .{ .grow = 1.0 },
            .height = .fit,
            .fontSize = fontSize,
            .textWrapping = .character,
            .padding = .block(2),
        },
    })({
        forbear.text(text);
    });
}

fn App() void {
    forbear.component(.{})({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
                .direction = .vertical,
                .padding = .all(20),
                .background = .{ .color = .{ 0.05, 0.05, 0.08, 1.0 } },
            },
        })({
            forbear.ProfilingMetrics(.{});

            const shift = @as(usize, @intCast(frameCount / 10));
            const sizeShift = @as(usize, @intCast(frameCount / 5));

            var keyBuf: [16]u8 = undefined;
            for (0..unicode_blocks.len) |i| {
                const blockIdx = (i + shift) % unicode_blocks.len;
                const baseSizes = [_]f32{ 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32, 36 };
                const fontSize = baseSizes[(i + sizeShift) % baseSizes.len];
                const key = std.fmt.bufPrint(&keyBuf, "line{d}", .{i}) catch unreachable;
                TextLine(key, unicode_blocks[blockIdx], fontSize);
            }
        });
    });
}

fn renderingMain(
    allocator: std.mem.Allocator,
    renderer: *forbear.Graphics.Renderer,
    io: std.Io,
    window: *forbear.Window,
) !void {
    var arenaAllocator = std.heap.ArenaAllocator.init(allocator);
    defer arenaAllocator.deinit();
    errdefer window.running = false;

    const arena = arenaAllocator.allocator();

    try forbear.registerFont("Inter", @embedFile("inter_font"));

    var frameStart = std.Io.Clock.awake.now(io);

    while (window.running) {
        defer _ = arenaAllocator.reset(.retain_capacity);

        try forbear.frame(.{
            .arena = arena,
            .viewportSize = renderer.viewportSize(),
            .baseStyle = .{
                .blendMode = .normal,
                .font = try forbear.useFont("Inter"),
                .color = .{ 1.0, 1.0, 1.0, 1.0 },
                .textWrapping = .character,
                .fontSize = 24,
                .fontWeight = 400,
                .lineHeight = 1.0,
                .cursor = .default,
            },
        })({
            App();

            const rootTree = try forbear.layout();
            try renderer.drawFrame(
                arena,
                rootTree,
                .{ 0.05, 0.05, 0.08, 1.0 },
                window.targetFrameTimeNs(),
            );

            try forbear.update();
        });

        const frameEnd = std.Io.Clock.awake.now(io);
        const dtNs = frameEnd.toNanoseconds() - frameStart.toNanoseconds();
        const dtMs = @as(f64, @floatFromInt(dtNs)) / @as(f64, std.time.ns_per_ms);
        benchmark.recordFrame(dtMs);
        frameStart = frameEnd;

        frameCount += 1;
    }
    try renderer.waitIdle();
    benchmark.report();
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    var graphics = try forbear.Graphics.init(
        allocator,
        "text stress test",
    );
    defer graphics.deinit();

    const window = try forbear.Window.init(
        allocator,
        1200,
        800,
        "text stress test",
        "forbear.text_stress",
    );
    defer window.deinit();

    var renderer = try graphics.initRenderer(window);
    defer renderer.deinit();

    try forbear.init(allocator, init.io, window, &renderer);
    defer forbear.deinit();

    const renderingThread = try std.Thread.spawn(
        .{ .allocator = allocator },
        renderingMain,
        .{
            allocator,
            &renderer,
            init.io,
            window,
        },
    );
    defer renderingThread.join();

    try window.handleEvents();
}
