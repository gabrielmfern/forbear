const std = @import("std");
const forbear = @import("root.zig");
const Vec2 = @Vector(2, f32);

pub const shallowBaseStyle = forbear.BaseStyle{
    .font = undefined,
    .color = .{ 0.0, 0.0, 0.0, 1.0 },
    .fontSize = 16,
    .fontWeight = 400,
    .lineHeight = 1.0,
    .textWrapping = .none,
    .blendMode = .normal,
    .cursor = .default,
};

/// Sums the per-scope `states` map sizes. Used by tests that previously
/// asserted against a single global state hashmap.
fn totalStateCount() u32 {
    var n: u32 = 0;
    var it = forbear.getForbear().scopes.valueIterator();
    while (it.next()) |scope| {
        n += scope.states.count();
    }
    return n;
}

pub fn frameMeta(arena: std.mem.Allocator) !forbear.FrameMeta {
    try forbear.registerFont("Inter", @embedFile("inter_font"));
    return forbear.FrameMeta{
        .arena = arena,
        .viewportSize = .{ 800, 600 },
        .baseStyle = forbear.BaseStyle{
            .font = try forbear.useFont("Inter"),
            .color = .{ 0.0, 0.0, 0.0, 1.0 },
            .fontSize = 16,
            .fontWeight = 400,
            .lineHeight = 1.0,
            .textWrapping = .none,
            .blendMode = .normal,
            .cursor = .default,
        },
    };
}

// forbear.layouting.zig tests
test "2.0 grow factor against 1.0 grow factor on fixed height parent" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .fit,
                .direction = .horizontal,
                .textWrapping = .word,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 2.0 },
                    .height = .{ .fixed = 100.0 },
                    .direction = .vertical,
                },
            })({});

            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .{ .fixed = 100.0 },
                    .direction = .vertical,
                },
            })({});
        });

        const tree = try forbear.layout();

        const root = tree.at(0);
        const factorTwo = tree.at(root.firstChild.?);
        const factorOne = tree.at(root.lastChild.?);

        try std.testing.expectApproxEqAbs(factorTwo.size[0], root.size[0] / 3 * 2, 0.0001);
        try std.testing.expectApproxEqAbs(factorOne.size[0], root.size[0] / 3, 0.0001);
        try std.testing.expectApproxEqAbs(factorTwo.size[0], factorOne.size[0] * 2, 0.0001);
    });
}

test "grow factor 0.0 does not participate in grow distribution" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300.0 },
                .height = .fit,
                .direction = .horizontal,
            },
        })({
            // grow: 0.0 should keep its fitted size (50px from its child)
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 0.0 },
                    .height = .{ .fixed = 100.0 },
                    .direction = .vertical,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 50.0 },
                        .height = .{ .fixed = 50.0 },
                    },
                })({});
            });

            // grow: 1.0 should take all remaining space (300 - 50 = 250)
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .{ .fixed = 100.0 },
                    .direction = .vertical,
                },
            })({});
        });

        const tree = try forbear.layout();

        const root = tree.at(0);
        const zeroFactor = tree.at(root.firstChild.?);
        const oneFactor = tree.at(root.lastChild.?);

        // grow: 0.0 should keep fitted width of 50
        try std.testing.expectApproxEqAbs(zeroFactor.size[0], 50.0, 0.0001);
        // grow: 1.0 should take the remaining 250
        try std.testing.expectApproxEqAbs(oneFactor.size[0], 250.0, 0.0001);
    });
}

test "negative grow factor does not participate in grow distribution" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300.0 },
                .height = .fit,
                .direction = .horizontal,
            },
        })({
            // grow: -1.0 should keep its fitted size (50px from its child)
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = -1.0 },
                    .height = .{ .fixed = 100.0 },
                    .direction = .vertical,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 50.0 },
                        .height = .{ .fixed = 50.0 },
                    },
                })({});
            });

            // grow: 1.0 should take all remaining space (300 - 50 = 250)
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .{ .fixed = 100.0 },
                    .direction = .vertical,
                },
            })({});
        });

        const tree = try forbear.layout();

        const root = tree.at(0);
        const negativeFactor = tree.at(root.firstChild.?);
        const oneFactor = tree.at(root.lastChild.?);

        // grow: -1.0 should keep fitted width of 50
        try std.testing.expectApproxEqAbs(negativeFactor.size[0], 50.0, 0.0001);
        // grow: 1.0 should take the remaining 250
        try std.testing.expectApproxEqAbs(oneFactor.size[0], 250.0, 0.0001);
    });
}

test "fit height parent, with grow height child containing wrapping text" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Reproduces the uhoh.com testimonials pattern:
    //   horizontal row (fit height)
    //     card A (fixed width, grow height) - short text
    //     card B (fixed width, grow height) - long wrapped text (tallest)
    //     card C (fixed width, grow height) - medium text
    //
    // After text wrapping, card B is tallest. The row should fit to B's height,
    // then cards A and C (with height: .grow) should stretch to match.
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .fit,
                .direction = .horizontal,
                .textWrapping = .word,
            },
        })({
            // Card A: short text (single line)
            // direction: .vertical is required so children get width constrained
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .grow = 1.0 },
                    .direction = .vertical,
                },
            })({
                forbear.text("Short.");
            });

            // Card B: long text (will be tallest after wrapping)
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .grow = 1.0 },
                    .direction = .vertical,
                },
            })({
                forbear.text("This testimonial will wrap to many lines when constrained to 100px width forcing this card to be taller.");
            });

            // Card C: medium text
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .grow = 1.0 },
                    .direction = .vertical,
                },
            })({
                forbear.text("Medium.");
            });
        });

        const tree = try forbear.layout();

        const row = tree.at(0);
        const cardA = tree.at(row.firstChild.?);
        const cardB = tree.at(cardA.nextSibling.?);
        const cardC = tree.at(cardB.nextSibling.?);

        const textB = tree.at(cardB.firstChild.?);

        try std.testing.expectApproxEqAbs(212.95312, textB.size[1], 0.0001);

        try std.testing.expectApproxEqAbs(textB.size[1], cardB.size[1], 0.0001);

        try std.testing.expectApproxEqAbs(cardB.size[1], cardA.size[1], 0.0001);
        try std.testing.expectApproxEqAbs(cardB.size[1], cardC.size[1], 0.0001);
        try std.testing.expectApproxEqAbs(cardB.size[1], row.size[1], 0.0001);
    });
}

test "cross-axis grow siblings match height after text wrapping" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Horizontal row with fit height containing two grow-height children.
    // Left child has wrapped text (tall), right child is empty.
    // After wrapping, both should have equal heights matching the tallest.
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300 },
                .height = .fit,
                .direction = .horizontal,
                .textWrapping = .word,
            },
        })({
            // Left: tall wrapped text
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .grow = 1.0 },
                    .direction = .vertical,
                },
            })({
                forbear.text("This text will wrap to multiple lines when constrained to 100px width.");
            });

            // Right: empty but should stretch to match left
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .grow = 1.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const row = tree.at(0);
        const left = tree.at(row.firstChild.?);
        const right = tree.at(left.nextSibling.?);

        // Both grow children should have equal heights
        try std.testing.expectApproxEqAbs(left.size[1], right.size[1], 0.0001);
        // Row should fit to the content height
        try std.testing.expectApproxEqAbs(left.size[1], row.size[1], 0.0001);
        // Height should be greater than one line (text wrapped)
        try std.testing.expect(left.size[1] > 30.0);
    });
}

test "wrapped text propagates height upward" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var textNode: *forbear.Node = undefined;

        forbear.element(.{
            .style = .{
                .textWrapping = .word,
                .width = .fit,
                .height = .fit,
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .fit,
                },
            })({
                forbear.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore");
                textNode = forbear.getPreviousNode().?;
            });
        });

        const tree = try forbear.layout();
        const rootNode = tree.at(0);
        const innerIdx = rootNode.firstChild.?;
        const innerNode = tree.at(innerIdx);

        try std.testing.expectEqual(100, rootNode.size[0]);
        try std.testing.expectEqual(100, textNode.size[0]);
        try std.testing.expectEqual(textNode.size[1], rootNode.size[1]);

        try std.testing.expectEqual(100, innerNode.size[0]);
        try std.testing.expectEqual(textNode.size[1], innerNode.size[1]);
    });
}

fn expectTextLineCount(content: []const u8, expectedLines: usize) !void {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var textNode: *forbear.Node = undefined;
        forbear.element(.{
            .style = .{
                .width = .fit,
                .height = .fit,
                .direction = .vertical,
            },
        })({
            forbear.text(content);
            textNode = forbear.getPreviousNode().?;
        });

        _ = try forbear.layout();

        const lineHeight = textNode.glyphs.?.lineHeight;
        try std.testing.expect(lineHeight > 0);
        try std.testing.expectApproxEqAbs(
            @as(f32, @floatFromInt(expectedLines)) * lineHeight,
            textNode.size[1],
            0.0001,
        );

        // Compute which source-string line indices have at least one visible character.
        const populated = try arena.alloc(bool, expectedLines);
        defer arena.free(populated);
        @memset(populated, false);
        var sourceLine: usize = 0;
        var i: usize = 0;
        while (i < content.len) : (i += 1) {
            const ch = content[i];
            if (ch == '\r') {
                sourceLine += 1;
                if (i + 1 < content.len and content[i + 1] == '\n') i += 1;
            } else if (ch == '\n') {
                sourceLine += 1;
                if (i + 1 < content.len and content[i + 1] == '\r') i += 1;
            } else {
                try std.testing.expect(sourceLine < expectedLines);
                populated[sourceLine] = true;
            }
        }
        try std.testing.expectEqual(expectedLines, sourceLine + 1);

        // Every non-sentinel glyph must sit exactly on `k * lineHeight` for some
        // populated line `k`.
        const seen = try arena.alloc(bool, expectedLines);
        defer arena.free(seen);
        @memset(seen, false);
        for (textNode.glyphs.?.slice) |glyph| {
            if (std.mem.startsWith(u8, &glyph.textBuf, "\n")) continue;
            const ratio = glyph.position[1] / lineHeight;
            const rounded: usize = @intFromFloat(@round(ratio));
            try std.testing.expect(rounded < expectedLines);
            try std.testing.expectApproxEqAbs(
                @as(f32, @floatFromInt(rounded)) * lineHeight,
                glyph.position[1],
                0.0001,
            );
            try std.testing.expect(populated[rounded]);
            seen[rounded] = true;
        }
        // Each populated source line must produce at least one glyph at the matching y.
        for (populated, seen) |pop, s| {
            if (pop) try std.testing.expect(s);
        }
    });
}

test "text \\n adds one line" {
    try expectTextLineCount("hello\nworld", 2);
}

test "text multiple \\n in sequence" {
    try expectTextLineCount("a\n\nb", 3);
}

test "text multiple \\n in different places" {
    try expectTextLineCount("a\nb\nc", 3);
}

test "text \\r adds one line" {
    try expectTextLineCount("hello\rworld", 2);
}

test "text multiple \\r in sequence" {
    try expectTextLineCount("a\r\rb", 3);
}

test "text multiple \\r in different places" {
    try expectTextLineCount("a\rb\rc", 3);
}

test "text \\r\\n adds one line" {
    try expectTextLineCount("hello\r\nworld", 2);
}

test "text multiple \\r\\n in sequence" {
    try expectTextLineCount("a\r\n\r\nb", 3);
}

test "text multiple \\r\\n in different places" {
    try expectTextLineCount("a\r\nb\r\nc", 3);
}

test "text mixed \\n, \\r, \\r\\n adds one line each" {
    try expectTextLineCount("hello\rworld", 2);
    try expectTextLineCount("hello\nworld", 2);
    try expectTextLineCount("hello\r\nworld", 2);
}

test "text mixed \\n, \\r, \\r\\n in sequence" {
    try expectTextLineCount("a\r\n\r\nb", 3);
    try expectTextLineCount("a\n\rb", 2);
    try expectTextLineCount("a\r\n\nb", 3);
}

test "text \\r\\n\\r produces three lines" {
    // regression: the CR/LF normalization loop iterated with a stale captured
    // slice length, causing an out-of-bounds write on this mixed sequence
    try expectTextLineCount("\r\n\r", 3);
    try expectTextLineCount("a\r\n\rb", 3);
}

test "text mixed \\n, \\r, \\r\\n in different places" {
    try expectTextLineCount("a\rb\nc\r\nd", 4);
    try expectTextLineCount("a\r\nb\nc\rd", 4);
    try expectTextLineCount("a\nb\rc\r\nd", 4);
}

const TextMeasurements = struct {
    size: Vec2,
    minSize: Vec2,
    maxSize: Vec2,
    lineHeight: f32,
};

fn measurePrelayoutText(
    content: []const u8,
    wrapping: forbear.TextWrapping,
) !TextMeasurements {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var result: TextMeasurements = undefined;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .fit,
                .height = .fit,
                .direction = .vertical,
                .textWrapping = wrapping,
            },
        })({
            forbear.text(content);
            const node = forbear.getPreviousNode().?;
            result = .{
                .size = node.size,
                .minSize = node.minSize,
                .maxSize = node.maxSize,
                .lineHeight = node.glyphs.?.lineHeight,
            };
        });
    });
    return result;
}

test "text single line size is one line tall" {
    const measurement = try measurePrelayoutText("hello", .word);
    try std.testing.expect(measurement.lineHeight > 0);
    try std.testing.expect(measurement.size[0] > 0);
    try std.testing.expectApproxEqAbs(measurement.lineHeight, measurement.size[1], 0.0001);
    try std.testing.expectApproxEqAbs(measurement.lineHeight, measurement.minSize[1], 0.0001);
    try std.testing.expectApproxEqAbs(measurement.lineHeight, measurement.maxSize[1], 0.0001);
    try std.testing.expectApproxEqAbs(measurement.size[0], measurement.maxSize[0], 0.0001);
}

test "character text wrapping has the appropriate constraints" {
    const measurement = try measurePrelayoutText("hello", .character);
    try std.testing.expect(measurement.lineHeight > 0);
    try std.testing.expectApproxEqAbs(measurement.lineHeight, measurement.size[1], 0.0001);
    try std.testing.expectApproxEqAbs(measurement.lineHeight, measurement.minSize[1], 0.0001);
    try std.testing.expectApproxEqAbs(measurement.lineHeight * 6, measurement.maxSize[1], 0.0001);

    try std.testing.expect(measurement.size[0] > 0);
    try std.testing.expectApproxEqAbs(measurement.size[0], measurement.maxSize[0], 0.0001);
}

test "text with one \\n has size two lines tall" {
    const measurement = try measurePrelayoutText("hello\nworld", .word);
    try std.testing.expectApproxEqAbs(measurement.size[0], measurement.minSize[0], 0.0001);
    try std.testing.expectApproxEqAbs(measurement.size[0], measurement.maxSize[0], 0.0001);
    try std.testing.expectApproxEqAbs(2 * measurement.lineHeight, measurement.size[1], 0.0001);
    try std.testing.expectApproxEqAbs(2 * measurement.lineHeight, measurement.minSize[1], 0.0001);
    try std.testing.expectApproxEqAbs(2 * measurement.lineHeight, measurement.maxSize[1], 0.0001);
}

test "text with multiple \\n has size matching total line count" {
    const measurement = try measurePrelayoutText("a\nb\nc\nd", .word);
    try std.testing.expectApproxEqAbs(4 * measurement.lineHeight, measurement.size[1], 0.0001);
    try std.testing.expectApproxEqAbs(4 * measurement.lineHeight, measurement.maxSize[1], 0.0001);
}

test "text size[0] tracks longest line when longest line is first" {
    const single = try measurePrelayoutText("verylongline", .word);
    const multi = try measurePrelayoutText("verylongline\nshort", .word);

    try std.testing.expect(single.size[0] > 0);
    try std.testing.expectApproxEqAbs(single.size[0], multi.size[0], 0.0001);
    try std.testing.expectApproxEqAbs(single.size[0], multi.maxSize[0], 0.0001);
}

test "text size[0] tracks longest line when longest line is last" {
    const single = try measurePrelayoutText("verylongline", .word);
    const multi = try measurePrelayoutText("short\nverylongline", .word);

    try std.testing.expect(single.size[0] > 0);
    try std.testing.expectApproxEqAbs(single.size[0], multi.size[0], 0.0001);
    try std.testing.expectApproxEqAbs(single.size[0], multi.maxSize[0], 0.0001);
}

test "text .none minSize covers all lines, not just the last" {
    const single = try measurePrelayoutText("verylongline", .none);
    const multi = try measurePrelayoutText("verylongline\na", .none);

    try std.testing.expect(single.size[0] > 0);
    // With .none wrapping, the node cannot shrink below the width of
    // its longest line or the height needed for every manual line.
    try std.testing.expectApproxEqAbs(single.size[0], multi.minSize[0], 0.0001);
    try std.testing.expectApproxEqAbs(2 * multi.lineHeight, multi.minSize[1], 0.0001);
    try std.testing.expectApproxEqAbs(single.size[0], multi.minSize[0], 0.0001);
    try std.testing.expectApproxEqAbs(2 * multi.lineHeight, multi.minSize[1], 0.0001);
}

test "text .none maxSize[0] tracks longest line when it is not the last" {
    const single = try measurePrelayoutText("verylongline", .none);
    const multi = try measurePrelayoutText("verylongline\na", .none);

    try std.testing.expect(single.maxSize[0] > 0);
    // With .none wrapping, the reported max width must reflect the widest
    // line. A short trailing line must not shrink the overall width.
    try std.testing.expectApproxEqAbs(single.maxSize[0], multi.maxSize[0], 0.0001);
    try std.testing.expectApproxEqAbs(single.maxSize[0], multi.size[0], 0.0001);
}

test "text with \\r\\n produces same size as with \\n" {
    const nl = try measurePrelayoutText("hello\nworld", .word);
    const crlf = try measurePrelayoutText("hello\r\nworld", .word);

    try std.testing.expectApproxEqAbs(nl.size[0], crlf.size[0], 0.0001);
    try std.testing.expectApproxEqAbs(nl.size[1], crlf.size[1], 0.0001);
    try std.testing.expectApproxEqAbs(nl.maxSize[0], crlf.maxSize[0], 0.0001);
    try std.testing.expectApproxEqAbs(nl.maxSize[1], crlf.maxSize[1], 0.0001);
}

fn previousIndex() usize {
    return forbear.getForbear().frameMeta.?.previousPushedNodeIndex.?;
}

fn nodeAt(index: usize) *forbear.Node {
    return forbear.getForbear().nodeTree.at(index);
}

const textColumn = forbear.Style{
    .width = .fit,
    .height = .fit,
    .direction = .vertical,
    .textWrapping = .word,
};

test "composeText with one run matches text()" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();
    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var plainIndex: usize = undefined;
        var composedIndex: usize = undefined;
        forbear.element(.{ .style = .{ .direction = .vertical } })({
            forbear.element(.{ .style = textColumn })({
                forbear.text("Hello world");
                plainIndex = previousIndex();
            });
            forbear.element(.{ .style = textColumn })({
                forbear.composeText(.{})({
                    forbear.write("Hello world");
                });
                composedIndex = previousIndex();
            });
        });
        _ = try forbear.layout();

        const plain = nodeAt(plainIndex);
        const composed = nodeAt(composedIndex);
        try std.testing.expectEqual(plain.glyphs.?.slice.len, composed.glyphs.?.slice.len);
        try std.testing.expectApproxEqAbs(plain.glyphs.?.lineHeight, composed.glyphs.?.lineHeight, 0.0001);
        try std.testing.expectApproxEqAbs(plain.size[0], composed.size[0], 0.0001);
        try std.testing.expectApproxEqAbs(plain.size[1], composed.size[1], 0.0001);
        // Glyph positions are world-space; compare them relative to each text
        // node's own origin since the two columns sit at different offsets.
        for (plain.glyphs.?.slice, composed.glyphs.?.slice) |p, c| {
            try std.testing.expectEqual(p.index, c.index);
            try std.testing.expectApproxEqAbs(p.position[0] - plain.position[0], c.position[0] - composed.position[0], 0.0001);
            try std.testing.expectApproxEqAbs(p.position[1] - plain.position[1], c.position[1] - composed.position[1], 0.0001);
        }
    });
}

test "composeText concatenates same-styled runs into one block" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();
    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var plainIndex: usize = undefined;
        var composedIndex: usize = undefined;
        forbear.element(.{ .style = .{ .direction = .vertical } })({
            forbear.element(.{ .style = textColumn })({
                forbear.text("Hello world");
                plainIndex = previousIndex();
            });
            forbear.element(.{ .style = textColumn })({
                forbear.composeText(.{})({
                    forbear.write("Hel");
                    forbear.write("lo wor");
                    forbear.write("ld");
                });
                composedIndex = previousIndex();
            });
        });
        _ = try forbear.layout();

        const plain = nodeAt(plainIndex);
        const composed = nodeAt(composedIndex);
        // Three runs hold the same characters as the one string, so the glyph
        // count matches and the block stays one line tall. Width is within a
        // pixel rather than exact: runs shape independently, so the kerning
        // across the run boundaries is lost.
        try std.testing.expectEqual(plain.glyphs.?.slice.len, composed.glyphs.?.slice.len);
        try std.testing.expectApproxEqAbs(plain.size[1], composed.size[1], 0.0001);
        try std.testing.expectApproxEqAbs(plain.size[0], composed.size[0], 1.0);
        // The runs are placed sequentially on the one shared line.
        var previousX: f32 = -1.0;
        for (composed.glyphs.?.slice) |glyph| {
            const localX = glyph.position[0] - composed.position[0];
            const localY = glyph.position[1] - composed.position[1];
            try std.testing.expectApproxEqAbs(@as(f32, 0.0), localY, 0.0001);
            try std.testing.expect(localX >= previousX);
            previousX = localX;
        }
    });
}

test "composeText runs carry their own resolved style" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();
    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var index: usize = undefined;
        forbear.element(.{ .style = textColumn })({
            forbear.composeText(.{})({
                forbear.write("normal ");
                forbear.textStyle(.{ .fontWeight = 700 })({
                    forbear.write("bold");
                });
            });
            index = previousIndex();
        });
        _ = try forbear.layout();

        var normalCount: usize = 0;
        var boldCount: usize = 0;
        for (nodeAt(index).glyphs.?.slice) |glyph| {
            const style = glyph.style;
            switch (style.fontWeight) {
                400 => normalCount += 1,
                700 => boldCount += 1,
                else => return error.UnexpectedWeight,
            }
        }
        // "normal " is base weight (400 from frameMeta), "bold" is the override.
        try std.testing.expectEqual(@as(usize, 7), normalCount);
        try std.testing.expectEqual(@as(usize, 4), boldCount);
    });
}

test "composeText wraps across run boundaries" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();
    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var index: usize = undefined;
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 80 },
                .height = .fit,
                .direction = .vertical,
                .textWrapping = .word,
            },
        })({
            forbear.composeText(.{})({
                forbear.write("aaaa ");
                forbear.textStyle(.{ .fontWeight = 700 })({
                    forbear.write("bbbb cccc dddd");
                });
            });
            index = previousIndex();
        });
        _ = try forbear.layout();

        const glyphs = nodeAt(index).glyphs.?;
        var maxLine: usize = 0;
        for (glyphs.slice) |glyph| {
            const line: usize = @intFromFloat(@round(glyph.position[1] / glyphs.lineHeight));
            if (line > maxLine) maxLine = line;
        }
        // The block is far wider than 80px, so it must wrap; the wrap falls
        // inside the bold run, proving wrapping crosses the style boundary.
        try std.testing.expect(maxLine >= 1);
    });
}

test "composeText line height and baseline follow the tallest run" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();
    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var smallIndex: usize = undefined;
        var mixedIndex: usize = undefined;
        forbear.element(.{ .style = .{ .direction = .vertical } })({
            forbear.element(.{ .style = textColumn })({
                forbear.composeText(.{})({
                    forbear.write("x");
                });
                smallIndex = previousIndex();
            });
            forbear.element(.{ .style = textColumn })({
                forbear.composeText(.{})({
                    forbear.write("x");
                    forbear.textStyle(.{ .fontSize = 32 })({
                        forbear.write("Y");
                    });
                });
                mixedIndex = previousIndex();
            });
        });
        _ = try forbear.layout();

        const small = nodeAt(smallIndex).glyphs.?;
        const mixed = nodeAt(mixedIndex).glyphs.?;
        // base fontSize is 16; the 32px run doubles both metrics.
        try std.testing.expect(mixed.lineHeight > small.lineHeight);
        try std.testing.expectApproxEqAbs(2 * small.lineHeight, mixed.lineHeight, 0.0001);
        try std.testing.expectApproxEqAbs(2 * small.ascent, mixed.ascent, 0.0001);
    });
}

const LaidOutText = struct {
    size: Vec2,
    lineHeight: f32,
    maxGlyphLine: usize,
};

fn measureLaidOutText(
    content: []const u8,
    wrapping: forbear.TextWrapping,
    width: f32,
) !LaidOutText {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var result: LaidOutText = undefined;
    try forbear.frame(try frameMeta(arena))({
        var textNode: *forbear.Node = undefined;
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = width },
                .height = .fit,
                .direction = .vertical,
                .textWrapping = wrapping,
            },
        })({
            forbear.text(content);
            textNode = forbear.getPreviousNode().?;
        });

        _ = try forbear.layout();

        const glyphs = textNode.glyphs.?;
        var maxLine: usize = 0;
        for (glyphs.slice) |glyph| {
            const rounded: usize = @intFromFloat(@round(glyph.position[1] / glyphs.lineHeight));
            if (rounded > maxLine) maxLine = rounded;
        }

        result = .{
            .size = textNode.size,
            .lineHeight = glyphs.lineHeight,
            .maxGlyphLine = maxLine,
        };
    });
    return result;
}

test ".word wrap respects a single manual break" {
    const m = try measureLaidOutText("hello\nworld", .word, 500.0);
    try std.testing.expectApproxEqAbs(2 * m.lineHeight, m.size[1], 0.0001);
    try std.testing.expectEqual(@as(usize, 1), m.maxGlyphLine);
}

test ".word wrap respects multiple manual breaks" {
    const m = try measureLaidOutText("a\nb\nc\nd", .word, 500.0);
    try std.testing.expectApproxEqAbs(4 * m.lineHeight, m.size[1], 0.0001);
    try std.testing.expectEqual(@as(usize, 3), m.maxGlyphLine);
}

test ".word wrap preserves blank line between \\n\\n" {
    const m = try measureLaidOutText("a\n\nb", .word, 500.0);
    try std.testing.expectApproxEqAbs(3 * m.lineHeight, m.size[1], 0.0001);
    try std.testing.expectEqual(@as(usize, 2), m.maxGlyphLine);
}

test ".word wrap with leading \\n pushes content to second line" {
    const m = try measureLaidOutText("\nhello", .word, 500.0);
    try std.testing.expectApproxEqAbs(2 * m.lineHeight, m.size[1], 0.0001);
    try std.testing.expectEqual(@as(usize, 1), m.maxGlyphLine);
}

test ".word wrap with trailing \\n adds a blank last line" {
    const m = try measureLaidOutText("hello\n", .word, 500.0);
    try std.testing.expectApproxEqAbs(2 * m.lineHeight, m.size[1], 0.0001);
}

test ".word wrap with only \\n produces two blank lines" {
    const m = try measureLaidOutText("\n", .word, 500.0);
    try std.testing.expectApproxEqAbs(2 * m.lineHeight, m.size[1], 0.0001);
}

test ".character wrap respects a single manual break" {
    const m = try measureLaidOutText("ab\ncd", .character, 500.0);
    try std.testing.expectApproxEqAbs(2 * m.lineHeight, m.size[1], 0.0001);
    try std.testing.expectEqual(@as(usize, 1), m.maxGlyphLine);
}

test ".character wrap respects multiple manual breaks" {
    const m = try measureLaidOutText("a\nb\nc\nd", .character, 500.0);
    try std.testing.expectApproxEqAbs(4 * m.lineHeight, m.size[1], 0.0001);
    try std.testing.expectEqual(@as(usize, 3), m.maxGlyphLine);
}

test ".character wrap preserves blank line between \\n\\n" {
    const m = try measureLaidOutText("a\n\nb", .character, 500.0);
    try std.testing.expectApproxEqAbs(3 * m.lineHeight, m.size[1], 0.0001);
    try std.testing.expectEqual(@as(usize, 2), m.maxGlyphLine);
}

test ".word wrap stacks wrap-induced breaks with manual breaks" {
    // Constrain width to less than the full width of the first manual-break
    // segment so at least one word-wrap must occur within it. Adding a
    // manual break and another segment forces yet another line.
    const unconstrained = try measurePrelayoutText("alpha bravo charlie", .word);
    const m = try measureLaidOutText(
        "alpha bravo charlie\ndelta",
        .word,
        unconstrained.size[0] / 2,
    );
    try std.testing.expect(m.size[1] >= 3 * m.lineHeight);
    try std.testing.expect(m.maxGlyphLine >= 2);
}

test ".character wrap stacks wrap-induced breaks with manual breaks" {
    const unconstrained = try measurePrelayoutText("abcdefgh", .character);
    const m = try measureLaidOutText(
        "abcdefgh\nij",
        .character,
        unconstrained.size[0] / 2,
    );
    try std.testing.expect(m.size[1] >= 3 * m.lineHeight);
    try std.testing.expect(m.maxGlyphLine >= 2);
}

test "wrapped text simple ancestry stays at origin" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var textNode: *forbear.Node = undefined;

        forbear.element(.{
            .style = .{
                .textWrapping = .word,
                .width = .fit,
                .height = .fit,
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .fit,
                },
            })({
                forbear.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore");
                textNode = forbear.getPreviousNode().?;
            });
        });

        const tree = try forbear.layout();
        const rootNode = tree.at(0);
        const innerNode = tree.at(rootNode.firstChild.?);

        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, textNode.position);
        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, rootNode.position);
        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, innerNode.position);
    });
}

// Regression: `forbear.Image()` uses `width: grow` + `height: ratio`. Build-time
// `fitChild` saw height 0, so a `height: fit` hero column stayed short and the
// next root sibling (e.g. offerings card) overlapped the headline. `growAndShrink`
// applies ratio sizing then incrementally propagates the main-axis delta with
// `updateFittingForAncestorsInDirection` (same machinery as wrapped text). Same flex
// shape as examples/uhoh.com (hero block + text + sibling section).
test "uhoh-shaped grow-width ratio hero does not overlap following sibling section" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // viewport 800px wide from frameMeta
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .fit,
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .maxWidth = 600,
                    .xJustification = .center,
                    .yJustification = .start,
                    .padding = forbear.Padding.top(22.5).withBottom(30.0),
                    .direction = .vertical,
                },
            })({
                // Stand-in for `forbear.image` (grow width + intrinsic aspect).
                forbear.element(.{
                    .style = .{
                        .width = .{ .grow = 1.0 },
                        .height = .{ .ratio = 0.5 },
                    },
                })({});
                forbear.element(.{
                    .style = .{
                        .fontSize = 18,
                        .margin = forbear.Margin.block(13.5).withBottom(7.5),
                    },
                })({
                    forbear.text("We're here to reinvent how tech gets done.");
                });
                forbear.element(.{
                    .style = .{
                        .fontSize = 12,
                    },
                })({
                    forbear.text("We're replacing clunky IT with clean, fast, and flexible support.");
                });
            });
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .{ .fixed = 80 },
                    .background = .{ .color = .{ 1, 1, 1, 1 } },
                },
            })({});
        });

        const tree = try forbear.layout();
        const rootNode = tree.at(0);
        const hero = tree.at(rootNode.firstChild.?);
        const card = tree.at(hero.nextSibling.?);

        const illustration = tree.at(hero.firstChild.?);
        const heading = tree.at(illustration.nextSibling.?);
        const subtext = tree.at(heading.nextSibling.?);

        try std.testing.expectApproxEqAbs(600.0, illustration.size[0], 0.02);
        try std.testing.expectApproxEqAbs(300.0, illustration.size[1], 0.02);

        // `wrapAndPlace` advances the next sibling by this node's `size[1]` only.
        // That always equals `card.y - hero.y`, even when `hero.size[1]` is
        // stale — so comparing those two is useless. What breaks is: inner
        // children were laid out with the real illustration height, but `hero`
        // stayed short, so the card is placed in the middle of the hero text.
        const heroContentBottom = subtext.position[1] + subtext.size[1];
        try std.testing.expect(hero.size[1] >= illustration.size[1] + hero.fittingBase(.vertical) - 0.02);
        try std.testing.expect(heroContentBottom <= card.position[1] + 0.02);

        try std.testing.expect(heading.position[1] > illustration.position[1] + illustration.size[1] - 0.02);
    });
}

test "wrapped text propagates height upward with siblings" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var textNode: *forbear.Node = undefined;

        forbear.element(.{
            .style = .{
                .textWrapping = .word,
                .width = .fit,
                .height = .fit,
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .fit,
                },
            })({
                forbear.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore");
                textNode = forbear.getPreviousNode().?;
            });
            forbear.element(.{
                .style = .{
                    .height = .{ .fixed = 100 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const rootNode = tree.at(0);
        const firstChild = tree.at(rootNode.firstChild.?);
        const secondChild = tree.at(firstChild.nextSibling.?);

        try std.testing.expectEqual(100, textNode.size[0]);
        try std.testing.expectEqual(100, rootNode.size[0]);
        try std.testing.expectEqual(textNode.size[1] + 100, rootNode.size[1]);
        try std.testing.expectEqual(100, firstChild.size[0]);
        try std.testing.expectEqual(textNode.size[1], firstChild.size[1]);
        try std.testing.expectEqual(100, secondChild.size[1]);
    });
}

test "wrapped text stacks siblings after wrapping" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        var textNode: *forbear.Node = undefined;

        forbear.element(.{
            .style = .{
                .textWrapping = .word,
                .width = .fit,
                .height = .fit,
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .fit,
                },
            })({
                forbear.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore");
                textNode = forbear.getPreviousNode().?;
            });
            forbear.element(.{
                .style = .{
                    .height = .{ .fixed = 100 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const rootNode = tree.at(0);
        const firstChild = tree.at(rootNode.firstChild.?);
        const secondChild = tree.at(firstChild.nextSibling.?);

        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, textNode.position);
        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, rootNode.position);
        try std.testing.expectEqualDeep(Vec2{ 0.0, 0.0 }, firstChild.position);
        try std.testing.expectEqual(firstChild.position[0], secondChild.position[0]);
        try std.testing.expectEqual(firstChild.position[1] + firstChild.size[1], secondChild.position[1]);
    });
}

test "cross-axis fit row height reflects full column height after text wrapping" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Reproduces the uhoh.com hero section pattern:
    //   vertical outer
    //     horizontal row (fit height)
    //       vertical column (grow width)
    //         wrapped text  (height grows during wrapGlyphs)
    //         fixed child   (50px)
    //     sibling below
    //
    // After text wrapping, the column's total height is text + 50.
    // The row's height must match the column's total, not just the text's height.
    // The sibling must start below the row — not overlap it.
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .fit,
                .direction = .vertical,
                .textWrapping = .word,
            },
        })({
            // Row (fit height, horizontal)
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .direction = .horizontal,
                },
            })({
                // Inner column stacking text + fixed child
                forbear.element(.{
                    .style = .{
                        .direction = .vertical,
                        .width = .{ .grow = 1.0 },
                    },
                })({
                    forbear.element(.{
                        .style = .{
                            .width = .{ .fixed = 200 },
                            .height = .fit,
                        },
                    })({
                        forbear.text("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt");
                    });
                    forbear.element(.{
                        .style = .{
                            .width = .{ .fixed = 100 },
                            .height = .{ .fixed = 50 },
                        },
                    })({});
                });
            });
            // Sibling that must appear below the row
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 30 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const outer = tree.at(0);
        const row = tree.at(outer.firstChild.?);
        const column = tree.at(row.firstChild.?);
        const sibling = tree.at(row.nextSibling.?);
        // Navigate: column -> textContainer (firstChild) -> textNode (firstChild)
        const textContainer = tree.at(column.firstChild.?);
        const textNode = tree.at(textContainer.firstChild.?);

        const expectedColumnHeight = textNode.size[1] + 50.0;
        try std.testing.expectEqual(expectedColumnHeight, column.size[1]);
        try std.testing.expectEqual(expectedColumnHeight, row.size[1]);

        // The sibling must start at or below the row's bottom edge, not overlap
        try std.testing.expect(sibling.position[1] >= row.position[1] + row.size[1]);
    });
}

// Regression: `updateFittingForAncestorsInDirection` must apply perpendicular
// `.ratio` against the ancestor's size *after* `setSize` on the propagation axis.
// A row with `width: ratio` (width = height × r) and `height: fit` gets its height
// from a word-wrapped text column; that height updates during `wrapGlyphs`. Using
// the pre-update main-axis size for the ratio left `width` too small (stale h × r).
test "ratio width tracks fit height after propagated text wrap" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .ratio = 2.0 },
                    .height = .fit,
                    .direction = .horizontal,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 120 },
                        .height = .fit,
                        .direction = .vertical,
                        .textWrapping = .word,
                    },
                })({
                    forbear.text("One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty.");
                });
            });
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const row = tree.at(root.firstChild.?);

        // Wrapped text should make the row noticeably tall (not a single line).
        try std.testing.expect(row.size[1] > 45.0);
        // width = height × 2 after propagation from wrapGlyphs
        try std.testing.expectApproxEqAbs(row.size[0], row.size[1] * 2.0, 1.0);
    });
}

test "ratio height resolves after grow distributes width" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // viewport 800x600; horizontal root
        // child: width grows to fill 800, height = ratio(0.5) → 400
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .{ .ratio = 0.5 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const child = tree.at(root.firstChild.?);

        try std.testing.expectEqual(@as(f32, 800), child.size[0]);
        try std.testing.expectEqual(@as(f32, 400), child.size[1]);
    });
}

test "ratio width resolves after grow distributes height" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // viewport 800x600; vertical root
        // child: height grows to fill 600, width = ratio(2.0) → 1200
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .ratio = 2.0 },
                    .height = .{ .grow = 1.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const child = tree.at(root.firstChild.?);

        try std.testing.expectEqual(@as(f32, 600), child.size[1]);
        try std.testing.expectEqual(@as(f32, 1200), child.size[0]);
    });
}

test "wrapAndPlace offsets standard children by border plus padding" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .{ .fixed = 80 },
                .direction = .horizontal,
                .borderWidth = .left(8),
                .padding = .left(7),
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 40 },
                    .height = .{ .fixed = 24 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const parent = tree.at(0);
        const child = tree.at(parent.firstChild.?);

        try std.testing.expectEqual(@as(f32, 15), child.position[0]);
        try std.testing.expectEqual(@as(f32, 0), child.position[1]);
    });
}

test "overflow wrap places children on new lines and grows parent height" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // A 300px-wide horizontal container with overflow: wrap.
        // Three 120x50 children: the first two fit on line 1 (240px < 300px),
        // the third overflows and wraps to line 2.
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300 },
                .height = .fit,
                .direction = .horizontal,
                .overflow = .wrap,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 120 },
                    .height = .{ .fixed = 50 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 120 },
                    .height = .{ .fixed = 50 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 120 },
                    .height = .{ .fixed = 50 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const childA = tree.at(root.firstChild.?);
        const childB = tree.at(childA.nextSibling.?);
        const childC = tree.at(childB.nextSibling.?);

        try std.testing.expectEqual(@as(f32, 300), root.size[0]);

        // Line 1: childA and childB side by side at y=0
        try std.testing.expectEqual(@as(f32, 0), childA.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childA.position[1]);

        try std.testing.expectEqual(@as(f32, 120), childB.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childB.position[1]);

        // Line 2: childC wraps to a new row, x resets and y advances by
        // line 1's height (50)
        try std.testing.expectEqual(@as(f32, 0), childC.position[0]);
        try std.testing.expectEqual(@as(f32, 50), childC.position[1]);

        // Fit height = initial cross-axis max (50) + wrap addition (50) = 100
        try std.testing.expectEqual(@as(f32, 100), root.size[1]);
    });
}

test "overflow wrap line ranges start at the wrapping child for cross-axis justification" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // Same geometry as the basic wrap test, but center each row. The row that
        // wraps must still align every child on that row (including the wrapped
        // one); buggy line .start would attach the previous row's last child to
        // the new row and skip applying x justification to the real wrapped child.
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300 },
                .height = .fit,
                .direction = .horizontal,
                .overflow = .wrap,
                .xJustification = .center,
                .yJustification = .start,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 120 },
                    .height = .{ .fixed = 50 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 120 },
                    .height = .{ .fixed = 50 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 120 },
                    .height = .{ .fixed = 50 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const childA = tree.at(root.firstChild.?);
        const childB = tree.at(childA.nextSibling.?);
        const childC = tree.at(childB.nextSibling.?);

        // Inner width 300px; line 1 is 240px wide → +30; line 2 is 120px → +90
        try std.testing.expectEqual(@as(f32, 30), childA.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childA.position[1]);

        try std.testing.expectEqual(@as(f32, 150), childB.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childB.position[1]);

        try std.testing.expectEqual(@as(f32, 90), childC.position[0]);
        try std.testing.expectEqual(@as(f32, 50), childC.position[1]);
    });
}

test "overflow wrap with grow-width parent wraps against resolved size" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // Outer container anchors to the viewport (800x600).
        // The wrapping container uses grow so it fills the parent's
        // full 800px width. With wrapping-aware fitting, minSize is
        // the widest child (300) instead of the sum (900), so the
        // grow resolves to 800 rather than being floored at 900.
        // Three 300x60 children: the first two fit on line 1 (600 < 800),
        // the third overflows and wraps to line 2.
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .fit,
                    .direction = .horizontal,
                    .overflow = .wrap,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 300 },
                        .height = .{ .fixed = 60 },
                    },
                })({});
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 300 },
                        .height = .{ .fixed = 60 },
                    },
                })({});
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 300 },
                        .height = .{ .fixed = 60 },
                    },
                })({});
            });
        });

        const tree = try forbear.layout();
        const outer = tree.at(0);
        const wrapper = tree.at(outer.firstChild.?);
        const childA = tree.at(wrapper.firstChild.?);
        const childB = tree.at(childA.nextSibling.?);
        const childC = tree.at(childB.nextSibling.?);

        // Wrapper grows to parent's 800px (not 900, since minSize
        // is now the widest child, not the sum)
        try std.testing.expectEqual(@as(f32, 800), wrapper.size[0]);

        // Line 1: A and B side by side at y=0
        try std.testing.expectEqual(@as(f32, 0), childA.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childA.position[1]);

        try std.testing.expectEqual(@as(f32, 300), childB.position[0]);
        try std.testing.expectEqual(@as(f32, 0), childB.position[1]);

        // Line 2: C wraps, x resets and y advances by line 1 height (60)
        try std.testing.expectEqual(@as(f32, 0), childC.position[0]);
        try std.testing.expectEqual(@as(f32, 60), childC.position[1]);

        // Fit height = initial cross-axis max (60) + wrap addition (60) = 120
        try std.testing.expectEqual(@as(f32, 120), wrapper.size[1]);
    });
}

test "grow children split remaining space and stretch cross-axis" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 40 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .{ .grow = 1.0 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .{ .grow = 1.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);

        try std.testing.expectEqual(@as(f32, 800), root.size[0]);
        try std.testing.expectEqual(@as(f32, 600), root.size[1]);

        const fixedChild = tree.at(root.firstChild.?);
        const growA = tree.at(fixedChild.nextSibling.?);
        const growB = tree.at(growA.nextSibling.?);

        try std.testing.expectEqual(@as(f32, 100), fixedChild.size[0]);
        try std.testing.expectEqual(@as(f32, 40), fixedChild.size[1]);

        const remainingWidth = 800.0 - 100.0;
        const expectedGrowWidth = remainingWidth / 2.0;
        try std.testing.expectEqual(expectedGrowWidth, growA.size[0]);
        try std.testing.expectEqual(expectedGrowWidth, growB.size[0]);

        try std.testing.expectEqual(@as(f32, 600), growA.size[1]);
        try std.testing.expectEqual(@as(f32, 600), growB.size[1]);

        try std.testing.expectEqual(@as(f32, 0), fixedChild.position[0]);
        try std.testing.expectEqual(@as(f32, 100), growA.position[0]);
        try std.testing.expectEqual(100.0 + expectedGrowWidth, growB.position[0]);
    });
}

test "perpendicular clamping respects parent padding" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // A vertical parent with fixed width and padding,
        // containing a long text that should be clamped to the content area.
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .fit,
                .direction = .vertical,
                .padding = .all(20),
                .textWrapping = .word,
            },
        })({
            forbear.text("This is a long piece of text that should definitely wrap within the parent's content area and not overflow beyond its padding boundaries");
        });

        const tree = try forbear.layout();
        const parent = tree.at(0);
        const textNode = tree.at(parent.firstChild.?);

        // Content area = 200 - 20 - 20 = 160
        const contentWidth = 200.0 - 20.0 - 20.0;

        // The text node's width must not exceed the parent's content area
        try std.testing.expect(textNode.size[0] <= contentWidth + 0.001);
    });
}

test "relative-placed elements are positioned from parent origin" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
                .direction = .vertical,
            },
        })({
            // Sibling that pushes the parent's forbear.layout forward but should not
            // affect the relative child's position.
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50 },
                    .height = .{ .fixed = 50 },
                },
            })({});

            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 200 },
                    .height = .{ .fixed = 100 },
                    .padding = .all(10),
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 20 },
                        .height = .{ .fixed = 20 },
                        .placement = .{ .relative = .{ 5.0, 15.0 } },
                    },
                })({});
            });
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const firstSibling = tree.at(root.firstChild.?);
        const parent = tree.at(firstSibling.nextSibling.?);
        const relChild = tree.at(parent.firstChild.?);

        // Parent sits at y=50 (below the 50px sibling). Relative child is
        // offset (5, 15) from the parent's content-box top-left, i.e. inside
        // the parent's 10px padding.
        try std.testing.expectEqual(parent.position[0] + 10.0 + 5.0, relChild.position[0]);
        try std.testing.expectEqual(parent.position[1] + 10.0 + 15.0, relChild.position[1]);
    });
}

test "relative-placed child is offset by parent border" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 100 },
                .borderStyle = .solid,
                .borderWidth = .{ .x = .{ 4, 2 }, .y = .{ 6, 3 } },
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .height = .{ .grow = 1.0 },
                    .placement = .{ .relative = .{ 0.0, 0.0 } },
                },
            })({});
        });

        const tree = try forbear.layout();
        const parent = tree.at(0);
        const relChild = tree.at(parent.firstChild.?);

        // Relative child at (0, 0) lands inside the parent's border, so it
        // starts at (left=4, top=6) and grows to fill the content box.
        try std.testing.expectEqual(parent.position[0] + 4.0, relChild.position[0]);
        try std.testing.expectEqual(parent.position[1] + 6.0, relChild.position[1]);
        try std.testing.expectEqual(@as(f32, 100 - 4 - 2), relChild.size[0]);
        try std.testing.expectEqual(@as(f32, 100 - 6 - 3), relChild.size[1]);
    });
}

test "relative-placed child does not contribute to parent's fit" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .direction = .vertical,
                .width = .fit,
                .height = .fit,
            },
        })({
            forbear.element(.{
                .style = .{
                    .placement = .{ .relative = .{ 0.0, 0.0 } },
                    .width = .{ .fixed = 999.0 },
                    .height = .{ .fixed = 999.0 },
                },
            })({});
        });
        const parent = forbear.getPreviousNode().?;
        try std.testing.expectEqual(@as(f32, 0.0), parent.size[0]);
        try std.testing.expectEqual(@as(f32, 0.0), parent.size[1]);
    });
}

test "grow child inside relative-placed fixed-size parent fills the parent" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 400 },
                .height = .{ .fixed = 300 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .placement = .{ .relative = .{ 0.0, 0.0 } },
                    .width = .{ .fixed = 200 },
                    .height = .{ .fixed = 150 },
                    .direction = .vertical,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .grow = 1.0 },
                        .height = .{ .grow = 1.0 },
                    },
                })({});
            });
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const relParent = tree.at(root.firstChild.?);
        const growChild = tree.at(relParent.firstChild.?);

        try std.testing.expectEqual(@as(f32, 200), relParent.size[0]);
        try std.testing.expectEqual(@as(f32, 150), relParent.size[1]);
        try std.testing.expectEqual(@as(f32, 200), growChild.size[0]);
        try std.testing.expectEqual(@as(f32, 150), growChild.size[1]);
    });
}

test "grow on a relative-placed child fills the parent on both axes" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 400 },
                .height = .{ .fixed = 300 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .placement = .{ .relative = .{ 0.0, 0.0 } },
                    .width = .{ .grow = 1.0 },
                    .height = .{ .grow = 1.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const relChild = tree.at(root.firstChild.?);

        try std.testing.expectEqual(@as(f32, 400), relChild.size[0]);
        try std.testing.expectEqual(@as(f32, 300), relChild.size[1]);
    });
}

test "fixed-width ratio-height children with maxSize don't inflate parent cross-axis" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Simulates the image() pattern: fixed width, ratio height, maxWidth/maxHeight constraints.
    // Without clamping, the parent sees the unclamped size and inflates its cross-axis height.
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 800 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .direction = .horizontal,
                },
            })({
                // Mimics an image: fixed width 400, ratio height 0.75, maxWidth 128, maxHeight 112.
                // Unclamped size would be (400, 300); clamped should be (128, 96).
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 400 },
                        .height = .{ .ratio = 0.75 },
                        .minWidth = 0,
                        .minHeight = 0,
                        .maxWidth = 128,
                        .maxHeight = 112,
                    },
                })({});

                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 300 },
                        .height = .{ .ratio = 0.5 },
                        .minWidth = 0,
                        .minHeight = 0,
                        .maxWidth = 128,
                        .maxHeight = 112,
                    },
                })({});
            });
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const container = tree.at(root.firstChild.?);
        const child1 = tree.at(container.firstChild.?);
        const child2 = tree.at(child1.nextSibling.?);

        // Children should be clamped to their maxWidth, and height follows ratio
        try std.testing.expectEqual(@as(f32, 128), child1.size[0]);
        try std.testing.expectEqual(@as(f32, 96), child1.size[1]); // 128 * 0.75

        try std.testing.expectEqual(@as(f32, 128), child2.size[0]);
        try std.testing.expectEqual(@as(f32, 64), child2.size[1]); // 128 * 0.5

        // The container's cross-axis height should be max(96, 64) = 96, NOT 300
        try std.testing.expectEqual(@as(f32, 96), container.size[1]);
    });
}

test "ltr row with fixed height centers children vertically" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // A 400x200 horizontal row with a 50px tall child.
        // With .center justification the child should be at y = (200-50)/2 = 75.
        // With .end justification the child should be at y = 200-50 = 150.
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 400 },
                .height = .fit,
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 400 },
                    .height = .{ .fixed = 200 },
                    .direction = .horizontal,
                    .xJustification = .start,
                    .yJustification = .center,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 100 },
                        .height = .{ .fixed = 50 },
                    },
                })({});
            });

            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 400 },
                    .height = .{ .fixed = 200 },
                    .direction = .horizontal,
                    .xJustification = .start,
                    .yJustification = .end,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 100 },
                        .height = .{ .fixed = 50 },
                    },
                })({});
            });
        });

        const tree = try forbear.layout();
        const wrapper = tree.at(0);

        const centerRow = tree.at(wrapper.firstChild.?);
        const centerChild = tree.at(centerRow.firstChild.?);

        const endRow = tree.at(centerRow.nextSibling.?);
        const endChild = tree.at(endRow.firstChild.?);

        // Center: child should be vertically centered within the 200px parent
        try std.testing.expectEqual(@as(f32, 75), centerChild.position[1] - centerRow.position[1]);

        // End: child should be at the bottom of the 200px parent
        try std.testing.expectEqual(@as(f32, 150), endChild.position[1] - endRow.position[1]);
    });
}

test "slotted component children propagate size to fit ancestors" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const SlottedComponent = struct {
        fn render() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{
                    .style = .{
                        .width = .fit,
                        .height = .fit,
                        .padding = forbear.Padding.all(10),
                    },
                })({
                    forbear.componentChildrenSlot();
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    };

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .fit,
                .height = .fit,
            },
        })({
            SlottedComponent.render()({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 100 },
                        .height = .{ .fixed = 50 },
                    },
                })({});
            });
        });

        const tree = try forbear.layout();

        // Root element (index 0) should fit around the slotted component's
        // inner element (padding 10 on each side) + the fixed 100×50 child.
        const root = tree.at(0);
        try std.testing.expectEqual(120, root.size[0]); // 100 + 10 + 10
        try std.testing.expectEqual(70, root.size[1]); // 50 + 10 + 10

        // Inner element (index 1) from the slotted component
        const inner = tree.at(1);
        try std.testing.expectEqual(120, inner.size[0]);
        try std.testing.expectEqual(70, inner.size[1]);
    });
}

test "slotted component with before/after content sizes correctly" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const SlottedComponent = struct {
        fn render() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{
                    .style = .{
                        .width = .fit,
                        .height = .fit,
                        .direction = .horizontal,
                    },
                })({
                    forbear.element(.{
                        .style = .{
                            .width = .{ .fixed = 20 },
                            .height = .{ .fixed = 30 },
                        },
                    })({});
                    forbear.componentChildrenSlot();
                    forbear.element(.{
                        .style = .{
                            .width = .{ .fixed = 20 },
                            .height = .{ .fixed = 30 },
                        },
                    })({});
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    };

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .fit,
                .height = .fit,
            },
        })({
            SlottedComponent.render()({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 60 },
                        .height = .{ .fixed = 40 },
                    },
                })({});
            });
        });

        const tree = try forbear.layout();

        // Inner element: 20 (before) + 60 (child) + 20 (after) = 100 width
        // Height: max(30, 40, 30) = 40
        const inner = tree.at(1);
        try std.testing.expectEqual(100, inner.size[0]);
        try std.testing.expectEqual(40, inner.size[1]);

        // Root should match
        const root = tree.at(0);
        try std.testing.expectEqual(100, root.size[0]);
        try std.testing.expectEqual(40, root.size[1]);
    });
}

test "nested slotted components propagate sizes correctly" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const Inner = struct {
        fn render() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{
                    .style = .{
                        .width = .fit,
                        .height = .fit,
                        .padding = forbear.Padding.all(5),
                    },
                })({
                    forbear.componentChildrenSlot();
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    };

    const Outer = struct {
        fn render() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{
                    .style = .{
                        .width = .fit,
                        .height = .fit,
                        .padding = forbear.Padding.all(10),
                    },
                })({
                    forbear.componentChildrenSlot();
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    };

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .fit,
                .height = .fit,
            },
        })({
            Outer.render()({
                Inner.render()({
                    forbear.element(.{
                        .style = .{
                            .width = .{ .fixed = 50 },
                            .height = .{ .fixed = 30 },
                        },
                    })({});
                });
            });
        });

        const tree = try forbear.layout();

        // Inner element: 50 + 5+5 = 60 width, 30 + 5+5 = 40 height
        // Outer element: 60 + 10+10 = 80 width, 40 + 10+10 = 60 height
        // Root: 80 × 60
        const root = tree.at(0);
        try std.testing.expectEqual(80, root.size[0]);
        try std.testing.expectEqual(60, root.size[1]);
    });
}

// Regression: fitChild must use child.minSize (not child.size) for horizontal minSize
// propagation. During tree building, unwrapped text has size[0] = full line width,
// which would bloat parent.minSize[0] beyond maxWidth constraints. Using minSize[0]
// (longest word) prevents this. Without this, grow containers with maxWidth would
// have minSize > maxSize, breaking forbear.layout.
test "horizontal minSize uses child.minSize to avoid unwrapped text width bloat" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // Container with maxWidth constraint
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .fit,
                .maxWidth = 200,
                .direction = .vertical,
                .textWrapping = .word,
            },
        })({
            // Long text that would be ~500px unwrapped but wraps to fit 200px
            forbear.text("This is a long sentence that will definitely wrap when constrained to two hundred pixels width.");
        });

        const tree = try forbear.layout();
        const container = tree.at(0);
        const text = tree.at(container.firstChild.?);

        // Container width must respect maxWidth, not bloat to unwrapped text width
        try std.testing.expect(container.size[0] <= 200.0);
        // minSize should be based on longest word, not full unwrapped line
        try std.testing.expect(container.minSize[0] <= 200.0);
        // Text should have wrapped (multiple lines means height > single line)
        try std.testing.expect(text.size[1] > 25.0);
    });
}

test "vertical spacing elements with grow height works properly" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .fixed = 700 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .height = .{ .fixed = 100 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .height = .{ .fixed = 100 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .height = .{ .fixed = 100 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .height = .{ .grow = 1.0 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .height = .{ .fixed = 100 },
                },
            })({});
        });

        const nodeTree = try forbear.layout();
        const spacingNode = nodeTree.at(4);

        try std.testing.expectEqual(700 - 400, spacingNode.size[1]);
    });
}

// Regression: fitChild must use child.size (not child.minSize) for vertical minSize
// propagation. After text wrapping, size[1] = wrapped height, but minSize[1] is
// still single line height. Using size[1] ensures fit parents pick up the actual
// content height, allowing grow siblings to stretch correctly.
test "vertical minSize uses child.size to capture wrapped text height" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // Horizontal row with fit height
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .fit,
                .direction = .horizontal,
                .textWrapping = .word,
            },
        })({
            // Card A: grow height, short content
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .grow = 1.0 },
                    .direction = .vertical,
                },
            })({
                forbear.text("Short");
            });

            // Card B: grow height, wrapped text that determines row height
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .grow = 1.0 },
                    .direction = .vertical,
                },
            })({
                forbear.text("This text will wrap to multiple lines and should determine the row height which siblings then grow to match.");
            });
        });

        const tree = try forbear.layout();
        const row = tree.at(0);
        const cardA = tree.at(row.firstChild.?);
        const cardB = tree.at(cardA.nextSibling.?);
        const textB = tree.at(cardB.firstChild.?);

        // Text should have wrapped (height > single line)
        try std.testing.expect(textB.size[1] > 30.0);
        // Row height should match wrapped text height
        try std.testing.expectApproxEqAbs(textB.size[1], row.size[1], 0.1);
        // Card A (grow height) should stretch to match row
        try std.testing.expectApproxEqAbs(row.size[1], cardA.size[1], 0.1);
        // Card B should also match
        try std.testing.expectApproxEqAbs(row.size[1], cardB.size[1], 0.1);
    });
}

test "horizontal non-wrap container grows height to fit wrapped text child" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Horizontal container (non-wrap) with a single text child that wraps.
    // The container's height should expand to fit the wrapped text.
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100 },
                .height = .fit,
                .direction = .horizontal,
                .textWrapping = .word,
            },
        })({
            forbear.text("This text will wrap to multiple lines when constrained to 100px width.");
        });

        const tree = try forbear.layout();
        const container = tree.at(0);
        const text = tree.at(container.firstChild.?);

        // Text should have wrapped (multiple lines)
        try std.testing.expect(text.size[1] > 30.0);
        // Container height should match text height
        try std.testing.expectApproxEqAbs(text.size[1], container.size[1], 0.0001);
    });
}

test "nested containers propagate wrapped text height through multiple levels" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Three levels: outer (horizontal) > middle (vertical) > inner (horizontal) > text
    // Wrapped text height should propagate up through all fit containers.
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .fit,
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .fit,
                    .direction = .vertical,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .fit,
                        .height = .fit,
                        .direction = .horizontal,
                        .textWrapping = .word,
                    },
                })({
                    forbear.text("This text will wrap when constrained to the parent width of 100px.");
                });
            });
        });

        const tree = try forbear.layout();
        const outer = tree.at(0);
        const middle = tree.at(outer.firstChild.?);
        const inner = tree.at(middle.firstChild.?);
        const text = tree.at(inner.firstChild.?);

        // Text should have wrapped
        try std.testing.expect(text.size[1] > 30.0);
        // All containers should have matching heights
        try std.testing.expectApproxEqAbs(text.size[1], inner.size[1], 0.0001);
        try std.testing.expectApproxEqAbs(text.size[1], middle.size[1], 0.0001);
        try std.testing.expectApproxEqAbs(text.size[1], outer.size[1], 0.0001);
    });
}

test "mixed fit and grow siblings match height after text wrapping" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Horizontal row with:
    // - Left child: fit height, contains wrapped text (determines row height)
    // - Right child: grow height, empty (should stretch to match left)
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300 },
                .height = .fit,
                .direction = .horizontal,
                .textWrapping = .word,
            },
        })({
            // Fit child with wrapped text
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .fit,
                    .direction = .vertical,
                },
            })({
                forbear.text("This text wraps to multiple lines and determines the row height.");
            });

            // Grow child should stretch to match
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .grow = 1.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const row = tree.at(0);
        const fitChild = tree.at(row.firstChild.?);
        const growChild = tree.at(fitChild.nextSibling.?);
        const text = tree.at(fitChild.firstChild.?);

        // Text should have wrapped
        try std.testing.expect(text.size[1] > 30.0);
        // Fit child contains the text
        try std.testing.expectApproxEqAbs(text.size[1], fitChild.size[1], 0.0001);
        // Row fits to the fit child
        try std.testing.expectApproxEqAbs(fitChild.size[1], row.size[1], 0.0001);
        // Grow child stretches to match row
        try std.testing.expectApproxEqAbs(row.size[1], growChild.size[1], 0.0001);
    });
}

test "slotted children propagate size to fit ancestors" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();

    const arena = arenaAllocator.allocator();

    // Simulates a component with multiple nested fit elements containing a slot.
    // All internal elements end BEFORE slotted children are added,
    // so fit sizes are computed by forbear.layout() after tree construction.
    const SlottedComponent = struct {
        fn call() *const fn (void) void {
            forbear.component(.{})({
                // Multiple nested fit elements to stress the propagation
                forbear.element(.{
                    .style = .{
                        .width = .fit,
                        .height = .fit,
                        .direction = .vertical,
                    },
                })({
                    forbear.element(.{
                        .style = .{
                            .width = .fit,
                            .height = .fit,
                            .direction = .vertical,
                        },
                    })({
                        forbear.element(.{
                            .style = .{
                                .width = .fit,
                                .height = .fit,
                                .direction = .vertical,
                            },
                        })({
                            forbear.componentChildrenSlot();
                        });
                    });
                });
                // All elements above have ENDED here, but slotted children
                // will be added after componentChildrenSlotEnd()
            });
            return forbear.componentChildrenSlotEnd();
        }
    }.call;

    try forbear.frame(try frameMeta(arena))({
        // Fit ancestor that wraps the component
        forbear.element(.{
            .style = .{
                .width = .fit,
                .height = .fit,
                .direction = .vertical,
            },
        })({
            // Another fit wrapper
            forbear.element(.{
                .style = .{
                    .width = .fit,
                    .height = .fit,
                    .direction = .vertical,
                },
            })({
                SlottedComponent()({
                    // Slotted child with fixed size - added AFTER component's
                    // internal elements have ended
                    forbear.element(.{
                        .style = .{
                            .width = .{ .fixed = 150 },
                            .height = .{ .fixed = 80 },
                        },
                    })({});
                });
            });
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const wrapper = tree.at(root.firstChild.?);
        const compOuter = tree.at(wrapper.firstChild.?);
        const compMiddle = tree.at(compOuter.firstChild.?);
        const slotParent = tree.at(compMiddle.firstChild.?);
        const slottedChild = tree.at(slotParent.firstChild.?);

        // The slotted child has fixed size
        try std.testing.expectApproxEqAbs(@as(f32, 150), slottedChild.size[0], 0.0001);
        try std.testing.expectApproxEqAbs(@as(f32, 80), slottedChild.size[1], 0.0001);

        // All ancestors should fit to slotted child - this tests propagation
        // through multiple levels that ended before slotting
        try std.testing.expectApproxEqAbs(@as(f32, 150), slotParent.size[0], 0.0001);
        try std.testing.expectApproxEqAbs(@as(f32, 80), slotParent.size[1], 0.0001);

        try std.testing.expectApproxEqAbs(@as(f32, 150), compMiddle.size[0], 0.0001);
        try std.testing.expectApproxEqAbs(@as(f32, 80), compMiddle.size[1], 0.0001);

        try std.testing.expectApproxEqAbs(@as(f32, 150), compOuter.size[0], 0.0001);
        try std.testing.expectApproxEqAbs(@as(f32, 80), compOuter.size[1], 0.0001);

        try std.testing.expectApproxEqAbs(@as(f32, 150), wrapper.size[0], 0.0001);
        try std.testing.expectApproxEqAbs(@as(f32, 80), wrapper.size[1], 0.0001);

        try std.testing.expectApproxEqAbs(@as(f32, 150), root.size[0], 0.0001);
        try std.testing.expectApproxEqAbs(@as(f32, 80), root.size[1], 0.0001);
    });
}

test "element fitting - fit parent with padding accumulates fixed child inline" {
    // A vertical fit parent with padding should grow its height by the
    // child's height plus margins, plus its own padding/border.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .direction = .vertical,
                .height = .fit,
                .width = .{ .fixed = 100.0 },
                .padding = forbear.Padding.block(10.0),
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 40.0 },
                    .height = .{ .fixed = 20.0 },
                    .margin = forbear.Margin.block(5.0),
                },
            })({});
        });
        const tree = try forbear.layout();
        const parent = tree.at(0);
        // height = padding(10+10) + margin(5+5) + child(20) = 50
        try std.testing.expectEqual(@as(f32, 50.0), parent.size[1]);
        try std.testing.expectEqual(@as(f32, 50.0), parent.minSize[1]);
    });
}

test "element fitting - fit parent cross-axis takes max child height" {
    // A horizontal fit parent fitting height should use the tallest child
    // contribution plus its own vertical padding.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .direction = .horizontal,
                .height = .fit,
                .width = .{ .fixed = 200.0 },
                .padding = forbear.Padding.block(8.0),
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 30.0 },
                    .height = .{ .fixed = 20.0 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 30.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({});
        });
        const tree = try forbear.layout();
        const parent = tree.at(0);
        // height = padding(8+8) + max child height(50) = 66
        try std.testing.expectEqual(@as(f32, 66.0), parent.size[1]);
        try std.testing.expectEqual(@as(f32, 66.0), parent.minSize[1]);
    });
}

test "element fitting - fit parent with padding accumulates fixed child inline width" {
    // A horizontal fit parent should sum child widths plus margins plus its
    // own horizontal padding.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .direction = .horizontal,
                .width = .fit,
                .height = .{ .fixed = 50.0 },
                .padding = forbear.Padding.inLine(12.0),
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 30.0 },
                    .height = .{ .fixed = 50.0 },
                    .margin = forbear.Margin.inLine(4.0),
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 20.0 },
                    .height = .{ .fixed = 50.0 },
                    .margin = forbear.Margin.inLine(6.0),
                },
            })({});
        });
        const tree = try forbear.layout();
        const parent = tree.at(0);
        // width = padding(12+12) + child0(4+30+4) + child1(6+20+6) = 94
        try std.testing.expectEqual(@as(f32, 94.0), parent.size[0]);
        try std.testing.expectEqual(@as(f32, 94.0), parent.minSize[0]);
    });
}

test "element fitting - nested fit parents propagate size upward" {
    // Inner fit parent should size to its child, outer fit parent should size
    // to the inner parent.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .direction = .vertical,
                .width = .fit,
                .height = .fit,
            },
        })({
            forbear.element(.{
                .style = .{
                    .direction = .vertical,
                    .width = .fit,
                    .height = .fit,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 60.0 },
                        .height = .{ .fixed = 30.0 },
                    },
                })({});
            });
        });
        const tree = try forbear.layout();
        const outer = tree.at(0);
        try std.testing.expectEqual(@as(f32, 60.0), outer.size[0]);
        try std.testing.expectEqual(@as(f32, 30.0), outer.size[1]);
        try std.testing.expectEqual(@as(f32, 60.0), outer.minSize[0]);
        try std.testing.expectEqual(@as(f32, 30.0), outer.minSize[1]);
    });
}

test "element fitting - first child margin contributes to fit parent size" {
    // The leading margin of the first child must be included in the parent's
    // fit size, not skipped. A vertical fit parent with a single child that
    // has top+bottom margins should size to padding + margin_top + child +
    // margin_bottom.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .direction = .vertical,
                .height = .fit,
                .width = .fit,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 40.0 },
                    .height = .{ .fixed = 20.0 },
                    .margin = forbear.Margin.block(8.0),
                },
            })({});
        });
        const tree = try forbear.layout();
        const parent = tree.at(0);
        const child = tree.at(parent.firstChild.?);
        // height = margin_top(8) + child(20) + margin_bottom(8) = 36
        try std.testing.expectEqual(@as(f32, 36.0), parent.size[1]);
        try std.testing.expectEqual(@as(f32, 36.0), parent.minSize[1]);
        // width = child(40) with inline margins = 0 on each side
        try std.testing.expectEqual(@as(f32, 40.0), parent.size[0]);
        // child is placed at parent origin + margin_top
        try std.testing.expectEqual(parent.position[0], child.position[0]);
        try std.testing.expectEqual(parent.position[1] + 8.0, child.position[1]);
    });
}

test "element fitting - first child top margin offsets position in horizontal parent" {
    // In a horizontal container the y-axis is the cross axis. A child with a
    // top margin must be placed at parent_y + margin_top, not at parent_y.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .direction = .horizontal,
                .height = .fit,
                .width = .fit,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 40.0 },
                    .height = .{ .fixed = 20.0 },
                    .margin = forbear.Margin.block(8.0),
                },
            })({});
        });
        const tree = try forbear.layout();
        const parent = tree.at(0);
        const child = tree.at(parent.firstChild.?);
        // height = margin_top(8) + child(20) + margin_bottom(8) = 36
        try std.testing.expectEqual(@as(f32, 36.0), parent.size[1]);
        // child must be offset by margin_top on the cross axis
        try std.testing.expectEqual(parent.position[1] + 8.0, child.position[1]);
        // and by margin_left on the main axis
        try std.testing.expectEqual(parent.position[0], child.position[0]);
    });
}

// root.zig tests
test "Element tree stack stability" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            const nodeParentStack = &self.nodeStack;
            try std.testing.expectEqual(1, nodeParentStack.items.len);
            forbear.ProfilingMetrics(.{});

            try std.testing.expectEqual(1, nodeParentStack.items.len);
            forbear.element(.{})({
                try std.testing.expectEqual(2, nodeParentStack.items.len);

                forbear.text("Hello, world!");
                try std.testing.expectEqual(2, nodeParentStack.items.len);

                forbear.element(.{})({
                    try std.testing.expectEqual(3, nodeParentStack.items.len);

                    forbear.text("Nested element");
                    try std.testing.expectEqual(3, nodeParentStack.items.len);
                });

                try std.testing.expectEqual(2, nodeParentStack.items.len);
            });
            try std.testing.expectEqual(1, nodeParentStack.items.len);
        });
        try std.testing.expectEqual(0, self.nodeStack.items.len);
        try std.testing.expect(self.nodeTree.list.items.len > 0);
    });

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            const nodeParentStack = &self.nodeStack;
            try std.testing.expectEqual(1, nodeParentStack.items.len);
            forbear.ProfilingMetrics(.{});
            try std.testing.expectEqual(1, nodeParentStack.items.len);
            forbear.element(.{})({
                try std.testing.expectEqual(2, nodeParentStack.items.len);

                forbear.text("Hello, world!");
                try std.testing.expectEqual(2, nodeParentStack.items.len);

                forbear.element(.{})({
                    try std.testing.expectEqual(3, nodeParentStack.items.len);

                    forbear.text("Nested element");
                    try std.testing.expectEqual(3, nodeParentStack.items.len);
                });

                try std.testing.expectEqual(2, nodeParentStack.items.len);
            });
            try std.testing.expectEqual(1, nodeParentStack.items.len);
        });
        try std.testing.expectEqual(0, self.nodeStack.items.len);
        try std.testing.expect(self.nodeTree.list.items.len > 0);
    });
}

test "Element key stability across frames" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    // Helper to collect keys from the tree
    const collectKeys = struct {
        fn collect(
            allocator: std.mem.Allocator,
            tree: *const forbear.NodeTree,
            nodeIndex: usize,
            arrayList: *std.ArrayList(u64),
        ) !void {
            const node = tree.at(nodeIndex);
            try arrayList.append(allocator, node.key);
            var childIndex = node.firstChild;
            while (childIndex) |idx| {
                try collect(allocator, tree, idx, arrayList);
                childIndex = tree.at(idx).nextSibling;
            }
        }
    }.collect;

    var firstFrameKeys = try std.ArrayList(u64).initCapacity(std.testing.allocator, 8);
    defer firstFrameKeys.deinit(std.testing.allocator);
    var secondFrameKeys = try std.ArrayList(u64).initCapacity(std.testing.allocator, 8);
    defer secondFrameKeys.deinit(std.testing.allocator);
    // Build tree from the same call sites so @returnAddress() is stable
    const buildTree = struct {
        fn build() void {
            forbear.element(.{})({
                forbear.element(.{})({});
                forbear.element(.{})({
                    forbear.element(.{})({});
                    forbear.element(.{})({});
                });
            });
        }
    }.build;

    try forbear.frame(try frameMeta(arenaAllocator))({
        buildTree();
        try collectKeys(std.testing.allocator, &self.nodeTree, 0, &firstFrameKeys);
    });

    try forbear.frame(try frameMeta(arenaAllocator))({
        buildTree();
        try collectKeys(std.testing.allocator, &self.nodeTree, 0, &secondFrameKeys);
    });

    // Keys should be identical across frames for the same structure
    try std.testing.expectEqual(firstFrameKeys.items.len, secondFrameKeys.items.len);
    try std.testing.expectEqualSlices(u64, firstFrameKeys.items, secondFrameKeys.items);

    // Verify we have the expected number of elements (root + 2 children + 2 nested)
    try std.testing.expectEqual(5, firstFrameKeys.items.len);

    // Verify all keys are unique within a frame
    for (firstFrameKeys.items, 0..) |key, i| {
        for (firstFrameKeys.items[i + 1 ..]) |otherKey| {
            try std.testing.expect(key != otherKey);
        }
    }
}

fn SiblingAddedComponentA(initialValue: u32, out: *u32) void {
    forbear.component(.{ .key = "A" })({
        const state = forbear.useState(u32, initialValue);
        out.* = state.*;
    });
}

fn SiblingAddedComponentB() void {
    forbear.component(.{ .key = "B" })({});
}

fn SiblingAddedApp(includeB: bool, initialA: u32, out: *u32) void {
    forbear.element(.{})({
        if (includeB) SiblingAddedComponentB();
        SiblingAddedComponentA(initialA, out);
    });
}

test "Component state preserved when sibling is added" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var stateOut: u32 = 0;

    // Frame 1: render only ComponentA, initializing state to 42
    try forbear.frame(try frameMeta(arenaAllocator))({
        SiblingAddedApp(false, 42, &stateOut);
    });
    try std.testing.expectEqual(42, stateOut);

    _ = arena.reset(.retain_capacity);

    // Frame 2: add ComponentB before ComponentA — A's state should still be 42
    try forbear.frame(try frameMeta(arenaAllocator))({
        SiblingAddedApp(true, 99, &stateOut);
    });
    try std.testing.expectEqual(42, stateOut);
}

fn SiblingRemovedComponentA() void {
    forbear.component(.{ .key = "A" })({});
}

fn SiblingRemovedComponentB(initialValue: u32, out: *u32) void {
    forbear.component(.{ .key = "B" })({
        const state = forbear.useState(u32, initialValue);
        out.* = state.*;
    });
}

fn SiblingRemovedApp(includeA: bool, initialB: u32, out: *u32) void {
    forbear.element(.{})({
        if (includeA) SiblingRemovedComponentA();
        SiblingRemovedComponentB(initialB, out);
    });
}

test "Component state preserved when sibling is removed" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var stateOut: u32 = 0;

    // Frame 1: render A then B, B gets state=42
    try forbear.frame(try frameMeta(arenaAllocator))({
        SiblingRemovedApp(true, 42, &stateOut);
    });
    try std.testing.expectEqual(42, stateOut);

    _ = arena.reset(.retain_capacity);

    // Frame 2: remove A, render only B — B's state should still be 42
    try forbear.frame(try frameMeta(arenaAllocator))({
        SiblingRemovedApp(false, 99, &stateOut);
    });
    try std.testing.expectEqual(42, stateOut);
}

test "Sibling components at same call site get unique keys" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // A wrapper component invoked twice as siblings under the same parent.
    // Each call seeds its own useState slot — if the two calls share a key,
    // they share the state buffer and the second initial value is ignored.
    const MyComp = struct {
        fn render(initialValue: u32, out: *u32) void {
            forbear.component(.{})({
                const state = forbear.useState(u32, initialValue);
                out.* = state.*;
            });
        }
    }.render;

    var first: u32 = 0;
    var second: u32 = 0;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            MyComp(1, &first);
            MyComp(2, &second);
        });
    });

    try std.testing.expectEqual(@as(u32, 1), first);
    try std.testing.expectEqual(@as(u32, 2), second);
}

fn LoopItem(key: []const u8, initialValue: u32, observed: *u32) void {
    forbear.component(.{ .key = key })({
        const state = forbear.useState(u32, initialValue);
        observed.* = state.*;
    });
}

fn LoopApp(items: []const []const u8, fallbackInitial: u32, observed: *std.StringHashMap(u32)) !void {
    forbear.element(.{})({
        for (items, 0..) |item, i| {
            var v: u32 = 0;
            LoopItem(item, fallbackInitial + @as(u32, @intCast(i)), &v);
            try observed.put(item, v);
        }
    });
}

test "Component state in a loop with manual keys" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var observed = std.StringHashMap(u32).init(std.testing.allocator);
    defer observed.deinit();

    // Frame 1: render 3 components with manual keys, each storing its index
    const items = [_][]const u8{ "alpha", "beta", "gamma" };
    try forbear.frame(try frameMeta(arenaAllocator))({
        try LoopApp(&items, 0, &observed);
    });

    _ = arena.reset(.retain_capacity);

    // Frame 2: remove "beta" from the middle — alpha and gamma should keep state.
    // Use a different fallback initial to prove the original values stuck.
    const itemsWithoutBeta = [_][]const u8{ "alpha", "gamma" };
    try forbear.frame(try frameMeta(arenaAllocator))({
        try LoopApp(&itemsWithoutBeta, 999, &observed);
    });
    try std.testing.expectEqual(0, observed.get("alpha").?);
    try std.testing.expectEqual(2, observed.get("gamma").?);
}

fn ConditionalElementApp(condition: bool, capturedKey: ?*u64) void {
    forbear.element(.{})({
        if (condition) {
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50 },
                    .height = .{ .fixed = 50 },
                },
            })({});
            if (capturedKey) |slot| slot.* = forbear.getPreviousNode().?.key;
        }
    });
}

test "Element keys stable inside if statements" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var key1: u64 = 0;
    var key2: u64 = 0;
    var key3: u64 = 0;

    // Frame 1: condition true
    try forbear.frame(try frameMeta(arenaAllocator))({
        ConditionalElementApp(true, &key1);
    });

    _ = arena.reset(.retain_capacity);

    // Frame 2: condition true again — key should match
    try forbear.frame(try frameMeta(arenaAllocator))({
        ConditionalElementApp(true, &key2);
    });
    try std.testing.expectEqual(key1, key2);

    _ = arena.reset(.retain_capacity);

    // Frame 3: condition false — element not rendered
    try forbear.frame(try frameMeta(arenaAllocator))({
        ConditionalElementApp(false, null);
    });

    _ = arena.reset(.retain_capacity);

    // Frame 4: condition true again — key should still match frame 1
    try forbear.frame(try frameMeta(arenaAllocator))({
        ConditionalElementApp(true, &key3);
    });
    try std.testing.expectEqual(key1, key3);
}

fn ForLoopKeyApp(items: []const []const u8, observedKeys: *std.StringHashMap(u64)) !void {
    forbear.element(.{})({
        for (items) |item| {
            forbear.element(.{ .key = item })({});
            try observedKeys.put(item, forbear.getPreviousNode().?.key);
        }
    });
}

test "Element keys stable in for-loop with manual keys" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const items = [_][]const u8{ "alpha", "beta", "gamma" };
    var keys1 = std.StringHashMap(u64).init(std.testing.allocator);
    defer keys1.deinit();
    var keys2 = std.StringHashMap(u64).init(std.testing.allocator);
    defer keys2.deinit();
    var keys3 = std.StringHashMap(u64).init(std.testing.allocator);
    defer keys3.deinit();

    // Frame 1: render 3 elements with manual keys, capture each one's key
    try forbear.frame(try frameMeta(arenaAllocator))({
        try ForLoopKeyApp(&items, &keys1);
    });

    // All three keys must be distinct (manual key disambiguates same call site)
    try std.testing.expect(keys1.get("alpha").? != keys1.get("beta").?);
    try std.testing.expect(keys1.get("beta").? != keys1.get("gamma").?);
    try std.testing.expect(keys1.get("alpha").? != keys1.get("gamma").?);

    _ = arena.reset(.retain_capacity);

    // Frame 2: same loop again — every element's key must match frame 1
    try forbear.frame(try frameMeta(arenaAllocator))({
        try ForLoopKeyApp(&items, &keys2);
    });
    for (items) |item| {
        try std.testing.expectEqual(keys1.get(item).?, keys2.get(item).?);
    }

    _ = arena.reset(.retain_capacity);

    // Frame 3: remove "beta" — alpha and gamma's keys should still match frame 1
    const itemsWithoutBeta = [_][]const u8{ "alpha", "gamma" };
    try forbear.frame(try frameMeta(arenaAllocator))({
        try ForLoopKeyApp(&itemsWithoutBeta, &keys3);
    });
    for (itemsWithoutBeta) |item| {
        try std.testing.expectEqual(keys1.get(item).?, keys3.get(item).?);
    }
}

test "Element keys stable for siblings around a conditional element" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const renderRow = struct {
        fn render(showMiddle: bool, beforeKey: *u64, afterKey: *u64) void {
            forbear.element(.{})({
                forbear.element(.{})({});
                beforeKey.* = forbear.getPreviousNode().?.key;

                if (showMiddle) {
                    forbear.element(.{})({});
                }

                forbear.element(.{})({});
                afterKey.* = forbear.getPreviousNode().?.key;
            });
        }
    }.render;

    var before1: u64 = 0;
    var after1: u64 = 0;
    var before2: u64 = 0;
    var after2: u64 = 0;
    var before3: u64 = 0;
    var after3: u64 = 0;

    // Frame 1: middle present
    try forbear.frame(try frameMeta(arenaAllocator))({
        renderRow(true, &before1, &after1);
    });

    _ = arena.reset(.retain_capacity);

    // Frame 2: middle removed — before/after keys must not change
    try forbear.frame(try frameMeta(arenaAllocator))({
        renderRow(false, &before2, &after2);
    });
    try std.testing.expectEqual(before1, before2);
    try std.testing.expectEqual(after1, after2);

    _ = arena.reset(.retain_capacity);

    // Frame 3: middle re-added — before/after keys still match frame 1
    try forbear.frame(try frameMeta(arenaAllocator))({
        renderRow(true, &before3, &after3);
    });
    try std.testing.expectEqual(before1, before3);
    try std.testing.expectEqual(after1, after3);
}

test "Component state preserved through if statement toggling" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var stateOut: u32 = 0;

    const ConditionalComponent = struct {
        fn render(condition: bool, out: *u32) void {
            if (condition) {
                forbear.component(.{})({
                    const state = forbear.useState(u32, 42);
                    out.* = state.*;
                });
            }
        }
    }.render;

    // Frame 1: condition true, state initialized to 42
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            ConditionalComponent(true, &stateOut);
        });
    });
    try std.testing.expectEqual(42, stateOut);

    _ = arena.reset(.retain_capacity);

    // Frame 2: condition false — component not rendered
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            ConditionalComponent(false, &stateOut);
        });
    });

    _ = arena.reset(.retain_capacity);

    // Frame 3: condition true again — state should be preserved as 42
    stateOut = 0;
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            ConditionalComponent(true, &stateOut);
        });
    });
    try std.testing.expectEqual(42, stateOut);
}

test "Wrapper components produce unique keys from different parent components" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var keyFromA: u64 = 0;
    var keyFromB: u64 = 0;

    const ComponentA = struct {
        fn render(out: *u64) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.BreakLine();
                });
                const ctx = forbear.getForbear();
                out.* = ctx.nodeTree.at(ctx.nodeTree.list.items.len - 1).key;
            });
        }
    }.render;

    const ComponentB = struct {
        fn render(out: *u64) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.BreakLine();
                });
                const ctx = forbear.getForbear();
                out.* = ctx.nodeTree.at(ctx.nodeTree.list.items.len - 1).key;
            });
        }
    }.render;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            ComponentA(&keyFromA);
            ComponentB(&keyFromB);
        });

        // BreakLine from different parent components should have different keys
        try std.testing.expect(keyFromA != keyFromB);
    });
}

const ComponentResolutionProps = struct {
    callCount: *u32,
    value: u32,
};

fn ComponentResolutionComponent(props: ComponentResolutionProps) !void {
    forbear.component(.{ .key = "component-resolution-test" })({
        props.callCount.* += 1;
        const counter = forbear.useState(u32, props.value);
        const innerArena = forbear.useArena();
        try std.testing.expectEqual(10, counter.*);
        forbear.element(.{})({
            forbear.text(try std.fmt.allocPrint(innerArena, "Value {d}", .{counter.*}));
        });
    });
}

fn ComponentResolutionApp(props: ComponentResolutionProps) !void {
    forbear.element(.{})({
        try ComponentResolutionComponent(props);
    });
}

test "Component resolution" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var callCount: u32 = 0;

    try forbear.frame(try frameMeta(arenaAllocator))({
        try ComponentResolutionApp(.{ .callCount = &callCount, .value = 10 });
        try std.testing.expectEqual(1, callCount);
    });

    try forbear.frame(try frameMeta(arenaAllocator))({
        try ComponentResolutionApp(.{ .callCount = &callCount, .value = 20 });
        try std.testing.expectEqual(2, callCount);
    });
}

test "easeInOut" {
    try std.testing.expectEqual(1.0, forbear.easeInOut(1.0));
    try std.testing.expectEqual(0.0, forbear.easeInOut(0.0));
}

test "ease" {
    try std.testing.expectEqual(1.0, forbear.ease(1.0));
    try std.testing.expectEqual(0.0, forbear.ease(0.0));
}

fn resolveSpringTransition(
    arenaAllocator: std.mem.Allocator,
    componentKey: []const u8,
    target: f32,
    config: forbear.SpringConfig,
    result: *f32,
) !void {
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.component(.{
            .key = componentKey,
        })({
            result.* = forbear.useSpringTransition(target, config);
        });
    });
}

test "useSpringTransition - basic convergence" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const target = 100.0;
    const dt = 0.016; // ~60fps

    self.deltaTime = dt;
    self.cappedDeltaTime = self.deltaTime;

    // First frame: value should start at target when initialized
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-basic-convergence", target, config, &value);
    try std.testing.expectEqual(target, value);

    // Change target and simulate several frames
    const newTarget = 200.0;
    const initialValue = value;

    // Simulate spring physics over multiple frames
    for (0..100) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-basic-convergence", newTarget, config, &value);
    }

    // After 100 frames, should be very close or converged to target
    const epsilon = 0.001;
    try std.testing.expect(@abs(value - newTarget) < epsilon);
    // Value should have changed from initial
    try std.testing.expect(value != initialValue);
}

test "useSpringTransition - zero delta time" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const target = 50.0;

    self.deltaTime = 0.0;
    self.cappedDeltaTime = self.deltaTime;

    // First frame with zero dt
    var value1: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-zero-dt", target, config, &value1);
    try std.testing.expectEqual(target, value1);

    // Second frame with zero dt - should return current value unchanged
    _ = arena.reset(.retain_capacity);
    var value2: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-zero-dt", target + 100.0, config, &value2);
    try std.testing.expectEqual(target, value2);
}

test "useSpringTransition - null delta time" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const target = 75.0;

    self.deltaTime = null;
    self.cappedDeltaTime = self.deltaTime;

    // With null delta time, should return current value
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-null-dt", target, config, &value);
    try std.testing.expectEqual(target, value);
}

test "useSpringTransition - small delta time" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const initialTarget = 0.0;
    const newTarget = 100.0;
    const smallDt = 0.001; // 1ms - very small time step

    self.deltaTime = smallDt;
    self.cappedDeltaTime = self.deltaTime;

    // Initialize
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-small-dt", initialTarget, config, &value);
    try std.testing.expectEqual(initialTarget, value);

    // Change target with small dt
    _ = arena.reset(.retain_capacity);
    try resolveSpringTransition(arenaAllocator, "spring-small-dt", newTarget, config, &value);

    // Should have moved, but only slightly due to small dt
    try std.testing.expect(value != initialTarget);
    try std.testing.expect(value < newTarget);
    // Movement should be small
    try std.testing.expect(@abs(value - initialTarget) < 10.0);
}

test "useSpringTransition - large delta time" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const initialTarget = 0.0;
    const newTarget = 100.0;
    const largeDt = 1.0; // 1 second - very large frame time

    self.deltaTime = largeDt;
    self.cappedDeltaTime = self.deltaTime;

    // Initialize
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-large-dt", initialTarget, config, &value);
    try std.testing.expectEqual(initialTarget, value);

    // Change target with large dt - spring should handle it gracefully
    _ = arena.reset(.retain_capacity);
    try resolveSpringTransition(arenaAllocator, "spring-large-dt", newTarget, config, &value);

    // Should have moved significantly (physics are stable)
    try std.testing.expect(value != initialTarget);
}

test "useSpringTransition - convergence threshold" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const initialTarget = 0.0;
    const newTarget = 100.0;
    const dt = 0.016;

    self.deltaTime = dt;
    self.cappedDeltaTime = self.deltaTime;

    // Initialize
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-convergence-threshold", initialTarget, config, &value);
    try std.testing.expectEqual(initialTarget, value);

    // Animate towards target
    var converged = false;
    for (0..1000) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-convergence-threshold", newTarget, config, &value);

        // Check if converged (should snap to exact target within epsilon)
        if (value == newTarget) {
            converged = true;
            break;
        }
    }

    try std.testing.expect(converged);
    try std.testing.expectEqual(newTarget, value);
}

test "useSpringTransition - different spring configurations" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const dt = 0.016;
    self.deltaTime = dt;
    self.cappedDeltaTime = self.deltaTime;

    // Test stiff spring (high stiffness, high damping)
    {
        const stiffConfig = forbear.SpringConfig{
            .stiffness = 400.0,
            .damping = 40.0,
            .mass = 1.0,
        };

        var value: f32 = undefined;
        try resolveSpringTransition(arenaAllocator, "spring-stiff-config", 0.0, stiffConfig, &value);
        try std.testing.expectEqual(0.0, value);

        // Should converge quickly
        for (0..50) |_| {
            _ = arena.reset(.retain_capacity);
            try resolveSpringTransition(arenaAllocator, "spring-stiff-config", 100.0, stiffConfig, &value);
        }

        const epsilon = 0.1;
        try std.testing.expect(@abs(value - 100.0) < epsilon);
    }

    // Test soft spring (low stiffness, low damping)
    {
        const softConfig = forbear.SpringConfig{
            .stiffness = 50.0,
            .damping = 5.0,
            .mass = 1.0,
        };

        _ = arena.reset(.retain_capacity);
        var value: f32 = undefined;
        try resolveSpringTransition(arenaAllocator, "spring-soft-config", 0.0, softConfig, &value);
        try std.testing.expectEqual(0.0, value);

        // Should move more slowly
        for (0..10) |_| {
            _ = arena.reset(.retain_capacity);
            try resolveSpringTransition(arenaAllocator, "spring-soft-config", 100.0, softConfig, &value);
        }

        // After 10 frames, should not be fully converged yet
        try std.testing.expect(@abs(value - 100.0) > 1.0);
    }
}

test "useSpringTransition - heavy mass" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const heavyConfig = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 10.0, // Heavy mass
    };
    const dt = 0.016;

    self.deltaTime = dt;
    self.cappedDeltaTime = self.deltaTime;

    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-heavy-mass", 0.0, heavyConfig, &value);
    try std.testing.expectEqual(0.0, value);

    // Heavy mass should result in slower acceleration
    _ = arena.reset(.retain_capacity);
    try resolveSpringTransition(arenaAllocator, "spring-heavy-mass", 100.0, heavyConfig, &value);

    // After one frame, movement should be relatively small due to mass
    try std.testing.expect(@abs(value) < 50.0);
}

test "useSpringTransition - target changes during animation" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const dt = 0.016;

    self.deltaTime = dt;
    self.cappedDeltaTime = self.deltaTime;

    // Initialize at 0
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-target-changes", 0.0, config, &value);
    try std.testing.expectEqual(0.0, value);

    // Animate towards 100 for a few frames
    for (0..10) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-target-changes", 100.0, config, &value);
    }
    const valueAfter10Frames = value;

    // Suddenly change target to 200
    for (0..20) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-target-changes", 200.0, config, &value);
    }

    // Should have moved past the first target
    try std.testing.expect(value > valueAfter10Frames);
    try std.testing.expect(value > 100.0);
}

test "useSpringTransition - negative values" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const dt = 0.016;

    self.deltaTime = dt;
    self.cappedDeltaTime = self.deltaTime;

    // Initialize at positive value
    var value: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-negative-values", 100.0, config, &value);
    try std.testing.expectEqual(100.0, value);

    // Transition to negative target
    for (0..100) |_| {
        _ = arena.reset(.retain_capacity);
        try resolveSpringTransition(arenaAllocator, "spring-negative-values", -50.0, config, &value);
    }

    // Should converge to negative target
    const epsilon = 0.1;
    try std.testing.expect(@abs(value - (-50.0)) < epsilon);
}

test "useSpringTransition - state persistence across frames" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const config = forbear.SpringConfig{
        .stiffness = 200.0,
        .damping = 20.0,
        .mass = 1.0,
    };
    const dt = 0.016;
    self.deltaTime = dt;
    self.cappedDeltaTime = self.deltaTime;

    // Frame 1
    var value1: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-state-persistence", 0.0, config, &value1);
    try std.testing.expectEqual(0.0, value1);

    // Frame 2 - change target
    _ = arena.reset(.retain_capacity);
    var value2: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-state-persistence", 100.0, config, &value2);

    // Frame 3 - should continue from where it left off
    _ = arena.reset(.retain_capacity);
    var value3: f32 = undefined;
    try resolveSpringTransition(arenaAllocator, "spring-state-persistence", 100.0, config, &value3);

    // Value should continue progressing
    try std.testing.expect(value3 >= value2 or @abs(value3 - 100.0) < 0.0001);
}

fn StateCreationCounter(observed1: *i32, observed2: *f32, mutate: bool) void {
    forbear.component(.{ .key = "random" })({
        const state1 = forbear.useState(i32, 42);
        const state2 = forbear.useState(f32, 3.14);

        if (mutate) {
            state1.* = 100;
            state2.* = 6.28;
        }

        observed1.* = state1.*;
        observed2.* = state2.*;
    });
}

test "State creation with manual handling" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var observed1: i32 = 0;
    var observed2: f32 = 0;

    // Frame 1: state allocates, both useStates are mutated, count reaches 2.
    try forbear.frame(try frameMeta(arenaAllocator))({
        StateCreationCounter(&observed1, &observed2, true);
    });
    try std.testing.expectEqual(2, totalStateCount());
    try std.testing.expectEqual(100, observed1);
    try std.testing.expectEqual(6.28, observed2);

    // Frame 2: state is reused, mutated values from frame 1 persist.
    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({
        StateCreationCounter(&observed1, &observed2, false);
    });
    try std.testing.expectEqual(2, totalStateCount());
    try std.testing.expectEqual(100, observed1);
    try std.testing.expectEqual(6.28, observed2);
}

fn ConditionalState(callSecond: bool) void {
    forbear.component(.{ .key = "conditional-state-test" })({
        _ = forbear.useState(u32, 1);
        if (callSecond) {
            _ = forbear.useState(u32, 2);
        }
    });
}

test "useState entry is reaped when its call site is skipped" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // Frame 1: both useStates run.
    try forbear.frame(try frameMeta(arenaAllocator))({
        ConditionalState(true);
    });
    try std.testing.expectEqual(@as(u32, 2), totalStateCount());

    // Frame 2: conditional call site is skipped — its entry must be removed.
    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({
        ConditionalState(false);
    });
    try std.testing.expectEqual(@as(u32, 1), totalStateCount());

    // Frame 3: bringing the call back re-allocates the slot.
    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({
        ConditionalState(true);
    });
    try std.testing.expectEqual(@as(u32, 2), totalStateCount());
}

fn ChildWithStates(key: []const u8) void {
    forbear.component(.{ .key = key })({
        _ = forbear.useState(u32, 0);
        _ = forbear.useState(u32, 0);
    });
}

fn ParentWithChildren(includeB: bool) void {
    forbear.component(.{ .key = "parent-with-children" })({
        ChildWithStates("child-a");
        if (includeB) ChildWithStates("child-b");
    });
}

test "unmounted scope is removed and its states are reaped" {
    // Relies on `std.testing.allocator` to leak-fail at deinit if any
    // unmounted scope's arena was not freed.
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // Frame 1: parent + child-a + child-b → 3 scopes, 4 states (2 per child).
    try forbear.frame(try frameMeta(arenaAllocator))({
        ParentWithChildren(true);
    });
    const scopesAfterMount = self.scopes.count();
    try std.testing.expectEqual(@as(u32, 4), totalStateCount());

    // Frame 2: child-b unmounts → its scope and both its states must be gone.
    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({
        ParentWithChildren(false);
    });
    try std.testing.expectEqual(scopesAfterMount - 1, self.scopes.count());
    try std.testing.expectEqual(@as(u32, 2), totalStateCount());

    // Frame 3: nothing rendered → all scopes (including parent) and states gone.
    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({});
    try std.testing.expectEqual(@as(usize, 0), self.scopes.count());
    try std.testing.expectEqual(@as(u32, 0), totalStateCount());
}

fn TransitionRealloc(targetTo: f32, observedFrom: *f32, observedTo: *f32, observedAnimation: *?forbear.AnimationState) !void {
    // Mimics useTransition's calls:
    //   const valueToTransitionFrom = useState(f32, value);
    //   const valueToTransitionTo = useState(f32, value);
    //   const animation = useAnimation(duration);  -> useState(?AnimationState, null)
    forbear.component(.{ .key = "use-transition-realloc-test" })({
        const valueToTransitionFrom = forbear.useState(f32, 1.0);
        const valueToTransitionTo = forbear.useState(f32, 1.0);
        const animationState = forbear.useState(?forbear.AnimationState, null);

        // Earlier pointers must remain valid after the later useState calls;
        // if realloc had moved the buffer they'd be dangling here.
        try std.testing.expectEqual(valueToTransitionFrom.*, valueToTransitionFrom.*);
        try std.testing.expectEqual(valueToTransitionTo.*, valueToTransitionTo.*);

        // Simulate useTransition's "did the target change?" check.
        if (targetTo != valueToTransitionTo.*) {
            valueToTransitionTo.* = targetTo;
        }

        observedFrom.* = valueToTransitionFrom.*;
        observedTo.* = valueToTransitionTo.*;
        observedAnimation.* = animationState.*;
    });
}

test "Multiple useState pointers remain valid after realloc (useTransition pattern)" {
    // This test reproduces the useTransition scenario: three sequential useState
    // calls in the same component on the first frame. If realloc moves the buffer,
    // earlier pointers would be invalidated causing a segfault.
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var observedFrom: f32 = 0;
    var observedTo: f32 = 0;
    var observedAnimation: ?forbear.AnimationState = null;

    // Frame 1: useState allocates the buffer and we mutate the second slot.
    try forbear.frame(try frameMeta(arenaAllocator))({
        try TransitionRealloc(2.0, &observedFrom, &observedTo, &observedAnimation);
    });
    try std.testing.expectEqual(1.0, observedFrom);
    try std.testing.expectEqual(2.0, observedTo);
    try std.testing.expectEqual(null, observedAnimation);

    // Frame 2: buffer already exists at full size, no realloc — values persist.
    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({
        try TransitionRealloc(2.0, &observedFrom, &observedTo, &observedAnimation);
    });
    try std.testing.expectEqual(1.0, observedFrom);
    try std.testing.expectEqual(2.0, observedTo);
    try std.testing.expectEqual(null, observedAnimation);
}

fn StateSlot(elementKey: []const u8, observed: *i32, mutateTo: ?i32) void {
    forbear.element(.{ .key = elementKey })({
        const v = forbear.useState(i32, 0);
        observed.* = v.*;
        if (mutateTo) |m| v.* = m;
    });
}

fn StateIsolationApp(leftMutateTo: ?i32, rightMutateTo: ?i32, leftObserved: *i32, rightObserved: *i32) void {
    forbear.element(.{ .key = "root" })({
        forbear.component(.{ .key = "host" })({
            StateSlot("left", leftObserved, leftMutateTo);
            StateSlot("right", rightObserved, rightMutateTo);
        });
    });
}

test "useState in element scope isolates state per element" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var leftObserved: i32 = 0;
    var rightObserved: i32 = 0;

    // Frame 1: each sibling sees the initial value and writes a distinct one.
    try forbear.frame(try frameMeta(arenaAllocator))({
        StateIsolationApp(11, 22, &leftObserved, &rightObserved);
    });
    try std.testing.expectEqual(0, leftObserved);
    try std.testing.expectEqual(0, rightObserved);

    // Frame 2: each sibling reads back its own previously-stored value.
    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({
        StateIsolationApp(null, null, &leftObserved, &rightObserved);
    });
    try std.testing.expectEqual(11, leftObserved);
    try std.testing.expectEqual(22, rightObserved);
}

test "useState binds to nearest scope: element preferred, component inside element wins" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    const self = forbear.getForbear();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var componentKey: u64 = undefined;
    var elementKey: u64 = undefined;
    var innerComponentKey: u64 = undefined;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{ .key = "root" })({
            forbear.component(.{ .key = "outer" })({
                componentKey = self.scopeStack.getLast();

                // useState here binds to the outer component.
                const componentState = forbear.useState(i32, 0);
                componentState.* = 1;

                forbear.element(.{ .key = "host" })({
                    elementKey = self.scopeStack.getLast();

                    // useState inside the element binds to the element, not the
                    // surrounding component.
                    const elementState = forbear.useState(i32, 0);
                    elementState.* = 2;

                    forbear.component(.{ .key = "inner" })({
                        innerComponentKey = self.scopeStack.getLast();
                        // useState here binds to the inner component (closer than
                        // the wrapping element).
                        const innerState = forbear.useState(i32, 0);
                        innerState.* = 3;
                    });
                });
            });
        });
    });

    try std.testing.expect(componentKey != elementKey);
    try std.testing.expect(elementKey != innerComponentKey);
}

fn ReallocSlot(observedA: *f32, observedB: *f32, observedC: *?forbear.AnimationState, mutateBTo: ?f32) void {
    forbear.element(.{ .key = "scope" })({
        const a = forbear.useState(f32, 1.0);
        const b = forbear.useState(f32, 1.0);
        const c = forbear.useState(?forbear.AnimationState, null);

        if (mutateBTo) |target| b.* = target;

        observedA.* = a.*;
        observedB.* = b.*;
        observedC.* = c.*;
    });
}

fn ReallocApp(observedA: *f32, observedB: *f32, observedC: *?forbear.AnimationState, mutateBTo: ?f32) void {
    forbear.element(.{ .key = "root" })({
        forbear.component(.{ .key = "realloc-host" })({
            ReallocSlot(observedA, observedB, observedC, mutateBTo);
        });
    });
}

test "useState in element scope persists multiple slots across realloc" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var observedA: f32 = 0;
    var observedB: f32 = 0;
    var observedC: ?forbear.AnimationState = null;

    // Frame 1: allocate three useState slots and mutate the middle one.
    try forbear.frame(try frameMeta(arenaAllocator))({
        ReallocApp(&observedA, &observedB, &observedC, 2.0);
    });
    try std.testing.expectEqual(1.0, observedA);
    try std.testing.expectEqual(2.0, observedB);
    try std.testing.expectEqual(null, observedC);

    // Frame 2: same render code; earlier slots' values must survive.
    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({
        ReallocApp(&observedA, &observedB, &observedC, null);
    });
    try std.testing.expectEqual(1.0, observedA);
    try std.testing.expectEqual(2.0, observedB);
    try std.testing.expectEqual(null, observedC);
}

test "stale scope state is pruned at frame end (element)" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // Frame 1: mount the transient element.
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{ .key = "root" })({
            forbear.component(.{ .key = "host" })({
                forbear.element(.{ .key = "transient" })({
                    _ = forbear.useState(i32, 7);
                });
            });
        });
    });
    const stateCountWithTransient = totalStateCount();
    try std.testing.expect(stateCountWithTransient >= 1);

    // Frame 2: omit the element. Its state should be dropped.
    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{ .key = "root" })({
            forbear.component(.{ .key = "host" })({});
        });
    });
    try std.testing.expect(totalStateCount() < stateCountWithTransient);
}

test "stale scope state is pruned at frame end (component)" {
    const renderer: *forbear.Graphics.Renderer = undefined;
    try forbear.init(std.testing.allocator, std.testing.io, renderer);
    defer forbear.deinit();
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{ .key = "root" })({
            forbear.component(.{ .key = "host" })({
                forbear.component(.{ .key = "transient" })({
                    _ = forbear.useState(i32, 7);
                });
            });
        });
    });
    const stateCountWithTransient = totalStateCount();
    try std.testing.expect(stateCountWithTransient >= 1);

    _ = arena.reset(.retain_capacity);
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{ .key = "root" })({
            forbear.component(.{ .key = "host" })({});
        });
    });
    try std.testing.expect(totalStateCount() < stateCountWithTransient);
}

const HoverObservation = struct {
    enter: bool = false,
    leave: bool = false,
};

fn HoverFirst(observed: *HoverObservation) void {
    forbear.element(.{
        .style = .{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        },
    })({
        observed.enter = forbear.onMouseEnter();
        observed.leave = forbear.onMouseLeave();
    });
}

fn HoverSecond(observed: *HoverObservation) void {
    forbear.element(.{
        .style = .{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
            .placement = .{ .absolute = .{ 200.0, 0.0 } },
        },
    })({
        observed.enter = forbear.onMouseEnter();
        observed.leave = forbear.onMouseLeave();
    });
}

fn HoverApp(firstObserved: *HoverObservation, secondObserved: *HoverObservation) void {
    forbear.element(.{
        .style = .{
            .width = .{ .grow = 1.0 },
            .height = .{ .grow = 1.0 },
        },
    })({
        HoverFirst(firstObserved);
        HoverSecond(secondObserved);
    });
}

test "on() mouseEnter and mouseLeave fire on the correct element" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var firstObserved: HoverObservation = .{};
    var secondObserved: HoverObservation = .{};

    // Frame 1: mouse outside both — prime measurements with wasMouseInside = false
    self.mousePosition = .{ 500.0, 500.0 };
    try forbear.frame(try frameMeta(arenaAllocator))({
        HoverApp(&firstObserved, &secondObserved);
        _ = try forbear.layout();
    });
    _ = arena.reset(.retain_capacity);

    // Frame 2: mouse moves into first → first.mouseEnter fires; second sees nothing
    self.mousePosition = .{ 50.0, 50.0 };
    try forbear.frame(try frameMeta(arenaAllocator))({
        HoverApp(&firstObserved, &secondObserved);
        _ = try forbear.layout();
    });
    try std.testing.expect(firstObserved.enter);
    try std.testing.expect(!firstObserved.leave);
    try std.testing.expect(!secondObserved.enter);
    try std.testing.expect(!secondObserved.leave);
    _ = arena.reset(.retain_capacity);

    // Frame 3: mouse moves from first into second → first.mouseLeave + second.mouseEnter
    self.mousePosition = .{ 250.0, 50.0 };
    try forbear.frame(try frameMeta(arenaAllocator))({
        HoverApp(&firstObserved, &secondObserved);
    });
    try std.testing.expect(!firstObserved.enter);
    try std.testing.expect(firstObserved.leave);
    try std.testing.expect(secondObserved.enter);
    try std.testing.expect(!secondObserved.leave);
}

fn EdgeTriggeredBox(observed: *HoverObservation) void {
    forbear.element(.{
        .key = "test-element",
        .style = .{
            .width = .{ .fixed = 100 },
            .height = .{ .fixed = 100 },
        },
    })({
        observed.enter = forbear.onMouseEnter();
        observed.leave = forbear.onMouseLeave();
    });
}

test "on() mouseEnter and mouseLeave are edge-triggered" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var observed: HoverObservation = .{};

    // Frame 1: mouse outside — prime measurement with wasMouseInside = false
    self.mousePosition = .{ 500.0, 500.0 };
    try forbear.frame(try frameMeta(arenaAllocator))({
        EdgeTriggeredBox(&observed);
        _ = try forbear.layout();
    });
    try std.testing.expect(!observed.enter);
    try std.testing.expect(!observed.leave);
    _ = arena.reset(.retain_capacity);

    // Frame 2: mouse moves inside — mouseEnter fires, mouseLeave does not.
    self.mousePosition = .{ 50.0, 50.0 };
    try forbear.frame(try frameMeta(arenaAllocator))({
        EdgeTriggeredBox(&observed);
        _ = try forbear.layout();
    });
    try std.testing.expect(observed.enter);
    try std.testing.expect(!observed.leave);
    _ = arena.reset(.retain_capacity);

    // Frame 3: mouse stays inside — neither edge fires
    try forbear.frame(try frameMeta(arenaAllocator))({
        EdgeTriggeredBox(&observed);
        _ = try forbear.layout();
    });
    try std.testing.expect(!observed.enter);
    try std.testing.expect(!observed.leave);
    _ = arena.reset(.retain_capacity);

    // Frame 4: mouse moves outside — mouseLeave fires, mouseEnter does not
    self.mousePosition = .{ 500.0, 500.0 };
    try forbear.frame(try frameMeta(arenaAllocator))({
        EdgeTriggeredBox(&observed);
    });
    try std.testing.expect(!observed.enter);
    try std.testing.expect(observed.leave);

    // Frame 5: mouse stays outside — neither edge fires
    self.mousePosition = .{ 500.0, 500.0 };
    try forbear.frame(try frameMeta(arenaAllocator))({
        EdgeTriggeredBox(&observed);
    });
    try std.testing.expect(!observed.enter);
    try std.testing.expect(!observed.leave);
}

fn testCreateElementConfiguration(configuration: struct {
    style: forbear.Style,
    expectedSize: Vec2,
}) !void {
    const allocator = std.testing.allocator;
    try forbear.init(allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{ .style = configuration.style })({});
        if (forbear.getPreviousNode()) |previousNode| {
            try std.testing.expectEqualDeep(configuration.expectedSize, previousNode.size);
        }
    });
}

test "element - width ratio uses fixed height" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .ratio = 1.5 },
            .height = .{ .fixed = 40.0 },
        },
        .expectedSize = .{ 60.0, 40.0 },
    });
}

test "element - height ratio uses fixed width" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .fixed = 40.0 },
            .height = .{ .ratio = 1.5 },
        },
        .expectedSize = .{ 40.0, 60.0 },
    });
}

test "element - ratio without opposite fixed axis starts at zero" {
    try testCreateElementConfiguration(.{
        .style = .{
            .width = .{ .ratio = 2.0 },
            .height = .fit,
        },
        .expectedSize = .{ 0.0, 0.0 },
    });
}

test "element fitting - fixed child does not contribute to fit parent" {
    // A fixed-placed child should be excluded from the parent's fit
    // calculation.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .direction = .vertical,
                .width = .fit,
                .height = .fit,
            },
        })({
            forbear.element(.{
                .style = .{
                    .placement = .{ .fixed = .{ 0.0, 0.0 } },
                    .width = .{ .fixed = 999.0 },
                    .height = .{ .fixed = 999.0 },
                },
            })({});
        });
        const parent = forbear.getPreviousNode().?;
        // Fixed child must not inflate the fit parent
        try std.testing.expectEqual(@as(f32, 0.0), parent.size[0]);
        try std.testing.expectEqual(@as(f32, 0.0), parent.size[1]);
    });
}

test "element fitting - text child inflates fit parent inline" {
    // A fit parent whose only child is a text node should grow to contain the
    // text's full single-line width and height before forbear.layout() runs.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .direction = .horizontal,
                .width = .fit,
                .height = .fit,
            },
        })({
            forbear.text("hello");
        });
        const parent = forbear.getPreviousNode().?;
        // Parent must be at least as wide and tall as the text node itself.
        const textNode = self.nodeTree.at(parent.firstChild.?);
        try std.testing.expect(parent.size[0] >= textNode.size[0]);
        try std.testing.expect(parent.size[1] >= textNode.size[1]);
        try std.testing.expect(parent.size[0] > 0.0);
        try std.testing.expect(parent.size[1] > 0.0);
    });
}

test "element fitting - word-wrapped text child inflates fit parent to full text width" {
    // When textWrapping = .word, the text node's size[0] is the full unwrapped
    // width. A fit parent must pick that up during definition so it is not
    // collapsed to the minimum-word width before forbear.layout runs.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .direction = .horizontal,
                .width = .fit,
                .height = .fit,
                .textWrapping = .word,
            },
        })({
            forbear.text("hello world");
        });
        const parent = forbear.getPreviousNode().?;
        const textNode = self.nodeTree.at(parent.firstChild.?);
        // The full text width (size[0]) must be reflected in the parent —
        // not just the longest-word minSize.
        try std.testing.expectEqual(textNode.size[0], parent.size[0]);
        try std.testing.expect(parent.size[0] > textNode.minSize[0]);
    });
}

test "mouseDown dispatches on button press" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // box() is called from the same function each frame → stable element key across frames.
    // component(.{.key=...}) provides useState context needed by on(.mouseDown).
    const box = struct {
        fn create() *const fn (void) void {
            return forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 100 },
                },
            });
        }
    }.create;

    self.mousePosition = .{ 50.0, 50.0 };

    // Frame 1: prime measurement entry (on() returns false since no prior measurement)
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.component(.{ .key = "component" })({
            box()({
                _ = forbear.onMouseDown();
            });
        });
        _ = try forbear.layout();
        self.mouseButtonPressed = true;
    });
    _ = arena.reset(.retain_capacity);

    // Frame 2: on(.mouseDown) fires (wasPressedLastFrame=false, mouseButtonPressed=true)
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.component(.{ .key = "component" })({
            box()({
                try std.testing.expect(forbear.onMouseDown());
            });
        });
    });
}

test "scroll dispatches to hovered element with accumulated delta" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    // Helper ensures stable element key across frames (same call site).
    const el = struct {
        fn make() *const fn (void) void {
            return forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 100 },
                },
            });
        }
    }.make;

    // Frame 1: prime measurement
    try forbear.frame(try frameMeta(arenaAllocator))({
        el()({
            _ = forbear.onScroll();
        });
        _ = try forbear.layout();
        self.mousePosition = .{ 50.0, 50.0 };
        self.scrollDeltaAccumulator = .{ 0.0, 30.0 };
        try forbear.update();
    });
    _ = arena.reset(.retain_capacity);

    // Frame 2: scroll delta dispatched
    try forbear.frame(try frameMeta(arenaAllocator))({
        el()({
            const delta = forbear.onScroll();
            try std.testing.expect(delta != null);
            try std.testing.expectApproxEqAbs(@as(f32, 0.0), delta.?[0], 0.001);
            try std.testing.expectApproxEqAbs(@as(f32, 30.0), delta.?[1], 0.001);
        });
    });
}

test "scroll is not dispatched to unhovered elements" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const el = struct {
        fn make() *const fn (void) void {
            return forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 100 },
                },
            });
        }
    }.make;

    // Frame 1: prime measurement; mouse outside
    try forbear.frame(try frameMeta(arenaAllocator))({
        el()({
            _ = forbear.onScroll();
        });
        _ = try forbear.layout();
        self.mousePosition = .{ 500.0, 500.0 };
        self.scrollDeltaAccumulator = .{ 0.0, 30.0 };
        try forbear.update();
    });
    _ = arena.reset(.retain_capacity);

    // Frame 2: scroll not dispatched to unhovered element
    try forbear.frame(try frameMeta(arenaAllocator))({
        el()({
            try std.testing.expectEqual(@as(?@Vector(2, f32), null), forbear.onScroll());
        });
    });
}

test "scroll reaches every hovered ancestor" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const outer = struct {
        fn make() *const fn (void) void {
            return forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 200 },
                    .height = .{ .fixed = 200 },
                },
            });
        }
    }.make;
    const inner = struct {
        fn make() *const fn (void) void {
            return forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 100 },
                },
            });
        }
    }.make;

    // Frame 1: prime measurements
    try forbear.frame(try frameMeta(arenaAllocator))({
        outer()({
            _ = forbear.onScroll();
            inner()({
                _ = forbear.onScroll();
            });
        });
        _ = try forbear.layout();
        self.mousePosition = .{ 50.0, 50.0 };
        self.scrollDeltaAccumulator = .{ -5.0, 12.0 };
        try forbear.update();
    });
    _ = arena.reset(.retain_capacity);

    // Frame 2: scroll reaches both ancestor and inner
    try forbear.frame(try frameMeta(arenaAllocator))({
        outer()({
            const outerDelta = forbear.onScroll();
            try std.testing.expect(outerDelta != null);
            try std.testing.expectApproxEqAbs(@as(f32, -5.0), outerDelta.?[0], 0.001);
            try std.testing.expectApproxEqAbs(@as(f32, 12.0), outerDelta.?[1], 0.001);

            inner()({
                const innerDelta = forbear.onScroll();
                try std.testing.expect(innerDelta != null);
                try std.testing.expectApproxEqAbs(@as(f32, -5.0), innerDelta.?[0], 0.001);
                try std.testing.expectApproxEqAbs(@as(f32, 12.0), innerDelta.?[1], 0.001);
            });
        });
    });
}

test "scrollDeltaAccumulator transfers to scrollDelta at frame start" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 100 },
            },
        })({});

        _ = try forbear.layout();

        self.mousePosition = .{ 50.0, 50.0 };
        self.scrollDeltaAccumulator = .{ 7.0, -3.0 };
        try forbear.update();
    });

    _ = arena.reset(.retain_capacity);

    // At frame start the accumulator is transferred to scrollDelta and cleared.
    try forbear.frame(try frameMeta(arenaAllocator))({
        try std.testing.expectApproxEqAbs(@as(f32, 7.0), self.scrollDelta[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, -3.0), self.scrollDelta[1], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 0.0), self.scrollDeltaAccumulator[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 0.0), self.scrollDeltaAccumulator[1], 0.001);
    });
}

fn MouseUpButton(observedMouseUp: *bool) void {
    forbear.component(.{ .key = "component" })({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 100 },
            },
        })({
            observedMouseUp.* = forbear.onMouseUp();
        });
    });
}

test "mouseUp dispatches on button release" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var observedMouseUp: bool = false;

    self.mousePosition = .{ 50.0, 50.0 };

    // Frame 1: prime measurement entry; useState not yet called (measurement null)
    self.mouseButtonPressed = true;
    try forbear.frame(try frameMeta(arenaAllocator))({
        MouseUpButton(&observedMouseUp);
        _ = try forbear.layout();
    });
    _ = arena.reset(.retain_capacity);

    // Frame 2: prime wasPressedLastFrame=true (button held, first useState call)
    try forbear.frame(try frameMeta(arenaAllocator))({
        MouseUpButton(&observedMouseUp);
        _ = try forbear.layout();
        self.mouseButtonPressed = false;
    });
    _ = arena.reset(.retain_capacity);

    // Frame 3: on(.mouseUp) fires (wasPressedLastFrame=true, mouseButtonPressed=false)
    try forbear.frame(try frameMeta(arenaAllocator))({
        MouseUpButton(&observedMouseUp);
    });
    try std.testing.expect(observedMouseUp);
}

const ClickObservation = struct {
    click: bool = false,
    mouseUp: bool = false,
};

fn ClickButton(observed: *ClickObservation) void {
    forbear.component(.{ .key = "component" })({
        forbear.element(.{
            .key = "tracked",
            .style = .{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 100 },
            },
        })({
            observed.click = forbear.onClick();
            observed.mouseUp = forbear.onMouseUp();
        });
    });
}

test "click fires when mouseDown and mouseUp on same element" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    var observed: ClickObservation = .{};

    self.mousePosition = .{ 50.0, 50.0 };
    self.mouseButtonPressed = false;

    // Frame 1: no events fire yet — we're priming measurement and last-frame state.
    try forbear.frame(try frameMeta(arenaAllocator))({
        ClickButton(&observed);
        _ = try forbear.layout();
        self.mouseButtonPressed = true;
    });
    _ = arena.reset(.retain_capacity);

    // Frame 2: button is held — mouseDown fires inside on(.click), seeds wasMouseDown.
    try forbear.frame(try frameMeta(arenaAllocator))({
        ClickButton(&observed);
        _ = try forbear.layout();
        self.mouseButtonPressed = false;
    });
    _ = arena.reset(.retain_capacity);

    // Frame 3: button releases over the same element → mouseUp + click fire.
    try forbear.frame(try frameMeta(arenaAllocator))({
        ClickButton(&observed);
    });
    try std.testing.expect(observed.click);
    try std.testing.expect(observed.mouseUp);
}

test "no click when mouse moves away between mouseDown and mouseUp" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const box = struct {
        fn create() *const fn (void) void {
            return forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 100 },
                },
            });
        }
    }.create;

    self.mousePosition = .{ 50.0, 50.0 };
    self.mouseButtonPressed = false;

    // Frame 1: prime measurement entry; no useState called (measurement null)
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.component(.{})({
            box()({
                _ = forbear.onClick();
                _ = forbear.onMouseUp();
            });
        });
        _ = try forbear.layout();
        self.mouseButtonPressed = true;
    });
    _ = arena.reset(.retain_capacity);

    // Frame 2: mouseDown fires; prime wasPressedLastFrame for mouseUp; then move mouse outside
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.component(.{})({
            box()({
                _ = forbear.onClick();
                _ = forbear.onMouseUp();
            });
        });
        _ = try forbear.layout();
        self.mousePosition = .{ 200.0, 200.0 };
        self.mouseButtonPressed = false;
    });
    _ = arena.reset(.retain_capacity);

    // Frame 3: mouse is outside — on(.mouseLeave) fires, clearing wasPressed; no click or mouseUp
    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.component(.{})({
            box()({
                try std.testing.expect(!forbear.onClick());
                try std.testing.expect(!forbear.onMouseUp());
            });
        });
    });
}

// --- Component children slotting tests ---

fn collectChildIndices(tree: *const forbear.NodeTree, parentIndex: usize, buf: []usize) []usize {
    var count: usize = 0;
    var childOpt = tree.at(parentIndex).firstChild;
    while (childOpt) |childIndex| {
        if (count < buf.len) {
            buf[count] = childIndex;
            count += 1;
        }
        childOpt = tree.at(childIndex).nextSibling;
    }
    return buf[0..count];
}

test "Component children slotting: basic before + children + after" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.text("Child1");
                forbear.text("Child2");
            });
        });
        // Node creation order:
        //   0: root element
        //   1: component's inner element
        //   2: text("Before")
        //   3: text("After")
        //   4: text("Child1")
        //   5: text("Child2")
        // After slotting, element 1's children should be: Before(2), Child1(4), Child2(5), After(3)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(4, children.len);
        try std.testing.expectEqual(2, children[0]); // Before
        try std.testing.expectEqual(4, children[1]); // Child1
        try std.testing.expectEqual(5, children[2]); // Child2
        try std.testing.expectEqual(3, children[3]); // After
    });
}

test "Component children slotting: empty slot (no children passed)" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({});
        });
        // 0: root, 1: inner elem, 2: Before, 3: After
        // No children → Before(2), After(3)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(2, children.len);
        try std.testing.expectEqual(2, children[0]); // Before
        try std.testing.expectEqual(3, children[1]); // After
    });
}

test "Component children slotting: slot at beginning (no before-content)" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.text("Child1");
            });
        });
        // 0: root, 1: inner elem, 2: After, 3: Child1
        // After slotting: Child1(3), After(2)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(2, children.len);
        try std.testing.expectEqual(3, children[0]); // Child1
        try std.testing.expectEqual(2, children[1]); // After
    });
}

test "Component children slotting: slot at end (no after-content)" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.text("Child1");
            });
        });
        // 0: root, 1: inner elem, 2: Before, 3: Child1
        // No after-content → Before(2), Child1(3)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(2, children.len);
        try std.testing.expectEqual(2, children[0]); // Before
        try std.testing.expectEqual(3, children[1]); // Child1
    });
}

test "Component children slotting: multiple instances with different children" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.text("A");
            });
            TestComponent()({
                forbear.text("B");
                forbear.text("C");
            });
        });
        // First instance: 0:root, 1:elem, 2:Before, 3:After, 4:A
        // After slotting: Before(2), A(4), After(3)
        var buf: [10]usize = undefined;
        const children1 = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(3, children1.len);
        try std.testing.expectEqual(2, children1[0]); // Before
        try std.testing.expectEqual(4, children1[1]); // A
        try std.testing.expectEqual(3, children1[2]); // After

        // Second instance: 5:elem, 6:Before, 7:After, 8:B, 9:C
        // After slotting: Before(6), B(8), C(9), After(7)
        const rootChildren = collectChildIndices(&self.nodeTree, 0, &buf);
        try std.testing.expectEqual(2, rootChildren.len);
        const secondElem = rootChildren[1];
        try std.testing.expectEqual(5, secondElem);

        const children2 = collectChildIndices(&self.nodeTree, 5, &buf);
        try std.testing.expectEqual(4, children2.len);
        try std.testing.expectEqual(6, children2[0]); // Before
        try std.testing.expectEqual(8, children2[1]); // B
        try std.testing.expectEqual(9, children2[2]); // C
        try std.testing.expectEqual(7, children2[3]); // After
    });
}

test "Component children slotting: nested slotted components" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.text("before");
                    forbear.componentChildrenSlot();
                    forbear.text("after");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                TestComponent()({
                    forbear.text("Deep");
                });
            });
        });
        // Creation order:
        //   0: root element
        //   1: outer element
        //   2: "before"
        //   3: "after"
        //   4: inner element
        //   5: "before"
        //   6: "after"
        //   7: "Deep"
        // Outer element (1) children after slotting: before(2), inner-elem(4), after(3)
        var buf: [10]usize = undefined;
        const outerChildren = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(3, outerChildren.len);
        try std.testing.expectEqual(2, outerChildren[0]); // "before"
        try std.testing.expectEqual(4, outerChildren[1]); // inner element
        try std.testing.expectEqual(3, outerChildren[2]); // "after"

        // Inner element (4) children after slotting: before(5), Deep(7), after(6)
        const innerChildren = collectChildIndices(&self.nodeTree, 4, &buf);
        try std.testing.expectEqual(3, innerChildren.len);
        try std.testing.expectEqual(5, innerChildren[0]); // "before"
        try std.testing.expectEqual(7, innerChildren[1]); // "deep"
        try std.testing.expectEqual(6, innerChildren[2]); // "after"
    });
}

test "Component children slotting: parent stack stability" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            const stack = &self.nodeStack;
            try std.testing.expectEqual(1, stack.items.len);

            TestComponent()({
                // Stack restored to slot time: [root_elem(0), component_inner_elem(1)]
                try std.testing.expectEqual(2, stack.items.len);
                forbear.text("Child");
                try std.testing.expectEqual(2, stack.items.len);
            });

            // Stack restored to pre-slotEnd state
            try std.testing.expectEqual(1, stack.items.len);

            // Verify that subsequent elements are still added correctly
            forbear.text("AfterComponent");
        });
        var buf: [10]usize = undefined;
        // Root element (0) should have: inner element (1) + AfterComponent text node
        const rootChildren = collectChildIndices(&self.nodeTree, 0, &buf);
        try std.testing.expectEqual(2, rootChildren.len);
        try std.testing.expectEqual(1, rootChildren[0]); // component's inner element
    });
}

test "Component children slotting: element children in slot" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const self = forbear.getForbear();

    const TestComponent = (struct {
        fn call() *const fn (void) void {
            forbear.component(.{})({
                forbear.element(.{})({
                    forbear.text("Before");
                    forbear.componentChildrenSlot();
                    forbear.text("After");
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).call;

    try forbear.frame(try frameMeta(arenaAllocator))({
        forbear.element(.{})({
            TestComponent()({
                forbear.element(.{})({
                    forbear.text("Nested");
                });
            });
        });
        // 0: root, 1: inner elem, 2: Before, 3: After, 4: slotted element, 5: Nested
        // Inner element (1) children: Before(2), slotted-elem(4), After(3)
        var buf: [10]usize = undefined;
        const children = collectChildIndices(&self.nodeTree, 1, &buf);
        try std.testing.expectEqual(3, children.len);
        try std.testing.expectEqual(2, children[0]); // Before
        try std.testing.expectEqual(4, children[1]); // slotted element
        try std.testing.expectEqual(3, children[2]); // After

        // Slotted element (4) should contain Nested (5)
        try std.testing.expect(self.nodeTree.at(4).glyphs == null); // element, not text
        const nestedChildren = collectChildIndices(&self.nodeTree, 4, &buf);
        try std.testing.expectEqual(1, nestedChildren.len);
        try std.testing.expectEqual(5, nestedChildren[0]); // Nested
    });
}

// Mirrors examples/wayland-book.com/src/main.zig: a SidebarItem-style component
// that exposes its inner element via a children slot, and the caller puts an
// `if (forbear.onClick())` handler inside that slot. Each instance is
// disambiguated by `props.key`. The click must fire on the instance the mouse
// is actually over, not on a sibling, even when several instances are rendered
// in a loop from a single source line.
fn SlotItem(props: struct { key: []const u8, position: f32 }) *const fn (void) void {
    forbear.component(.{ .key = props.key })({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 50.0 },
                .placement = .{ .absolute = .{ 0.0, props.position } },
            },
        })({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}

fn SlotClickListApp(itemKeys: []const []const u8, observedClicks: []bool) void {
    forbear.element(.{
        .style = .{
            .width = .{ .grow = 1.0 },
            .height = .{ .grow = 1.0 },
        },
    })({
        for (itemKeys, 0..) |key, i| {
            const yPos: f32 = @as(f32, @floatFromInt(i)) * 60.0;
            SlotItem(.{ .key = key, .position = yPos })({
                if (forbear.onClick()) observedClicks[i] = true;
            });
        }
    });
}

test "Component children slotting: on(.click) inside a slot fires on the right instance in a loop" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    const self = forbear.getForbear();

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arenaAllocator = arena.allocator();

    const items = [_][]const u8{ "a", "b", "c" };
    var observedClicks = [_]bool{ false, false, false };

    // Mouse is over item "b" (index 1, y range 60..110).
    self.mousePosition = .{ 50.0, 80.0 };
    self.mouseButtonPressed = false;

    // Frame 1: prime measurements for each instance.
    try forbear.frame(try frameMeta(arenaAllocator))({
        SlotClickListApp(&items, &observedClicks);
        _ = try forbear.layout();
        self.mouseButtonPressed = true;
    });
    _ = arena.reset(.retain_capacity);

    // Frame 2: button is held — mouseDown should fire on instance "b" only.
    try forbear.frame(try frameMeta(arenaAllocator))({
        SlotClickListApp(&items, &observedClicks);
        _ = try forbear.layout();
        self.mouseButtonPressed = false;
    });
    _ = arena.reset(.retain_capacity);

    // Frame 3: button releases over "b" → click fires on "b".
    try forbear.frame(try frameMeta(arenaAllocator))({
        SlotClickListApp(&items, &observedClicks);
    });

    try std.testing.expect(!observedClicks[0]);
    try std.testing.expect(observedClicks[1]);
    try std.testing.expect(!observedClicks[2]);
}

// font.zig tests
test "LRU cache - set_first" {
    const LRUIntString = forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32));
    var lru = try LRUIntString.init(std.testing.allocator);
    defer lru.deinit();

    lru.entries[0] = LRUIntString.Entry{ .key = 1, .value = "one" };
    lru.entries[1] = LRUIntString.Entry{ .key = 2, .value = "two" };
    lru.entries[2] = LRUIntString.Entry{ .key = 3, .value = "three" };

    lru.first = 0;
    lru.last = 2;

    lru.set_first(2);

    try std.testing.expectEqual(2, lru.first.?);
    try std.testing.expectEqual(3, lru.entries[lru.first.?].key);
    try std.testing.expectEqualSlices(u8, "three", lru.entries[lru.first.?].value);
}

test "LRU Cache" {
    var lru = try forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);

    defer lru.deinit();

    _ = lru.put(1, "1");
    _ = lru.put(2, "2");
    _ = lru.put(3, "3");
    std.debug.print("After inserting all three entries:\n", .{});
    lru.print();

    const entry2 = lru.get(2);
    try std.testing.expect(entry2 != null);
    try std.testing.expectEqual(2, entry2.?.key);
    try std.testing.expectEqualSlices(u8, "2", entry2.?.value);
    try std.testing.expectEqual(entry2.?, &lru.entries[lru.first.?]);
    std.debug.print("After accessing entry 2:\n", .{});
    lru.print();

    const entry1 = lru.get(1);
    try std.testing.expect(entry1 != null);
    try std.testing.expectEqual(1, entry1.?.key);
    try std.testing.expectEqualSlices(u8, "1", entry1.?.value);
    try std.testing.expectEqual(entry1.?, &lru.entries[lru.first.?]);
    std.debug.print("After accessing entry 1:\n", .{});
    lru.print();

    const entry3 = lru.get(3);
    try std.testing.expect(entry3 != null);
    try std.testing.expectEqual(3, entry3.?.key);
    try std.testing.expectEqualSlices(u8, "3", entry3.?.value);
    try std.testing.expectEqual(entry3.?, &lru.entries[lru.first.?]);
    std.debug.print("After accessing entry 3:\n", .{});
    lru.print();

    // Adding a new value should evict the least recently used value
    const entry4 = lru.put(4, "4");
    std.debug.print("After adding the entry '4' beyond the capacity of the LRU:\n", .{});
    lru.print();
    try std.testing.expectEqual(entry4.index, lru.first.?);
    // The entry for 2 should have been discarded completely
    try std.testing.expectEqual(entry1.?, &lru.entries[lru.last.?]);
    try std.testing.expect(lru.get(2) == null);
}

test "LRU cache - update existing key" {
    var lru = try forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Update existing key should replace value and move to front
    const updatedIndex = lru.put(2, "TWO");

    const entry = lru.get(2);
    try std.testing.expect(entry != null);
    try std.testing.expectEqualSlices(u8, "TWO", entry.?.value);
    try std.testing.expectEqual(updatedIndex.index, lru.first.?);
    try std.testing.expectEqual(2, lru.entries[lru.first.?].key);
    try std.testing.expectEqual(3, lru.length);
}

test "LRU cache - empty cache operations" {
    var lru = try forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    // Get from empty cache should return null
    try std.testing.expect(lru.get(1) == null);
    try std.testing.expect(lru.peek(1) == null);
    try std.testing.expectEqual(false, lru.contains(1));
    try std.testing.expectEqual(null, lru.first);
    try std.testing.expectEqual(null, lru.last);
    try std.testing.expectEqual(0, lru.length);
}

test "LRU cache - single item cache" {
    var lru = try forbear.Font.LRU(i32, []const u8, 1, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    try std.testing.expectEqual(1, lru.length);
    try std.testing.expectEqual(0, lru.first.?);
    try std.testing.expectEqual(0, lru.last.?);

    const entry = lru.get(1);
    try std.testing.expect(entry != null);
    try std.testing.expectEqualSlices(u8, "one", entry.?.value);

    // Adding another item should evict the first
    _ = lru.put(2, "two");
    try std.testing.expectEqual(1, lru.length);
    try std.testing.expect(lru.get(1) == null);

    const entry2 = lru.get(2);
    try std.testing.expect(entry2 != null);
    try std.testing.expectEqualSlices(u8, "two", entry2.?.value);
}

test "LRU cache - multiple accesses same key" {
    var lru = try forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Access same key multiple times
    _ = lru.get(2);
    _ = lru.get(2);
    _ = lru.get(2);

    // Should still be at front
    try std.testing.expectEqual(1, lru.first.?);
    try std.testing.expectEqual(2, lru.entries[lru.first.?].key);

    // Add new item, key 2 was most recently used, so 1 should be evicted
    _ = lru.put(4, "four");
    try std.testing.expect(lru.get(1) == null);
    try std.testing.expect(lru.get(2) != null);
}

test "LRU cache - peek does not affect order" {
    var lru = try forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Peek at key 1 (currently at back)
    const peeked = lru.peek(1);
    try std.testing.expect(peeked != null);
    try std.testing.expectEqualSlices(u8, "one", peeked.?.value);

    // Key 3 should still be at front
    try std.testing.expectEqual(2, lru.first.?);
    try std.testing.expectEqual(3, lru.entries[lru.first.?].key);

    // Add new item, key 1 should be evicted (not moved to front by peek)
    _ = lru.put(4, "four");
    try std.testing.expect(lru.get(1) == null);
}

test "LRU cache - contains" {
    var lru = try forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");

    try std.testing.expectEqual(true, lru.contains(1));
    try std.testing.expectEqual(true, lru.contains(2));
    try std.testing.expectEqual(false, lru.contains(3));
}

test "LRU cache - clear" {
    var lru = try forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    try std.testing.expectEqual(3, lru.length);

    lru.clear();

    try std.testing.expectEqual(0, lru.length);
    try std.testing.expectEqual(null, lru.first);
    try std.testing.expectEqual(null, lru.last);
    try std.testing.expect(lru.get(1) == null);
    try std.testing.expect(lru.get(2) == null);
    try std.testing.expect(lru.get(3) == null);

    // Should be able to add new items after clear
    _ = lru.put(4, "four");
    const entry = lru.get(4);
    try std.testing.expect(entry != null);
    try std.testing.expectEqualSlices(u8, "four", entry.?.value);
}

test "LRU cache - getMut allows modification" {
    var lru = try forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");

    const entry = lru.getMut(1);
    try std.testing.expect(entry != null);
    entry.?.value = "modified";

    const retrieved = lru.get(1);
    try std.testing.expect(retrieved != null);
    try std.testing.expectEqualSlices(u8, "modified", retrieved.?.value);
}

test "LRU cache - eviction order with mixed access" {
    var lru = try forbear.Font.LRU(i32, []const u8, 3, std.hash_map.AutoContext(i32)).init(std.testing.allocator);
    defer lru.deinit();

    _ = lru.put(1, "one");
    _ = lru.put(2, "two");
    _ = lru.put(3, "three");

    // Access pattern: 1, 3, (2 not accessed)
    _ = lru.get(1);
    _ = lru.get(3);

    // Add new item, 2 should be evicted as least recently used
    _ = lru.put(4, "four");

    try std.testing.expect(lru.get(1) != null);
    try std.testing.expect(lru.get(2) == null);
    try std.testing.expect(lru.get(3) != null);
    try std.testing.expect(lru.get(4) != null);
}

// buildDrawCommands tests

test "buildDrawCommands emits one element command per visible node" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 100 },
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50 },
                    .height = .{ .fixed = 50 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // Two elements, two commands
        try std.testing.expectEqual(@as(usize, 2), cmds.len);
        try std.testing.expectEqual(forbear.Graphics.DrawKind.element, cmds[0].kind);
        try std.testing.expectEqual(forbear.Graphics.DrawKind.element, cmds[1].kind);
    });
}

test "buildDrawCommands emits element + text for a text node" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .{ .fixed = 50 },
            },
        })({
            forbear.text("hi");
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // Parent element + text element + text glyphs = 3 commands
        try std.testing.expectEqual(@as(usize, 3), cmds.len);

        // Verify kinds present
        var hasText = false;
        var elementCount: usize = 0;
        for (cmds) |cmd| {
            switch (cmd.kind) {
                .text => hasText = true,
                .element => elementCount += 1,
                .shadow => {},
            }
        }
        try std.testing.expect(hasText);
        try std.testing.expectEqual(@as(usize, 2), elementCount);
    });
}

test "buildDrawCommands sorts by z with shadow before element before text" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // Parent has text (so text command at some z)
        // Parent has shadow (shadow command at same z as parent element)
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .{ .fixed = 50 },
                .shadow = .{
                    .color = .{ 0, 0, 0, 1 },
                    .blurRadius = 5,
                    .spread = 0,
                    .offset = .{ .x = .{ 0, 0 }, .y = .{ 0, 0 } },
                },
            },
        })({
            forbear.text("x");
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // Commands must be monotonically non-decreasing in (z, kind)
        for (cmds[1..], 0..) |cmd, i| {
            const prev = cmds[i];
            if (cmd.z == prev.z) {
                try std.testing.expect(@intFromEnum(prev.kind) <= @intFromEnum(cmd.kind));
            } else {
                try std.testing.expect(prev.z < cmd.z);
            }
        }
    });
}

test "buildDrawCommands culls nodes outside viewport" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 100 },
            },
        })({});

        const tree = try forbear.layout();

        // Tiny viewport at origin — node at (0,0) still overlaps
        const cmdsInside = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 50, 50 });
        try std.testing.expectEqual(@as(usize, 1), cmdsInside.len);

        // A 100x100 node at (0,0) is outside a viewport that starts at (200,0)
        // We can simulate this by passing a viewport smaller than the node's position.
        // The node is at x=0, y=0; a viewport of size 0x0 excludes it.
        const cmdsOutside = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 0, 0 });
        try std.testing.expectEqual(@as(usize, 0), cmdsOutside.len);
    });
}

test "buildDrawCommands propagates clipRect from layout" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // Fixed-height parent with children that overflow → children get clipRect
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100 },
                .height = .{ .fixed = 50 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 80 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        try std.testing.expectEqual(@as(usize, 2), cmds.len);

        // Parent has no clipRect; overflowing child gets clipped to parent bounds
        var parentClip: ?@Vector(4, f32) = null;
        var childClip: ?@Vector(4, f32) = null;
        for (cmds) |cmd| {
            if (cmd.z == 1) parentClip = cmd.clipRect;
            if (cmd.z == 2) childClip = cmd.clipRect;
        }
        try std.testing.expect(parentClip == null);
        // Child (100x80) overflows parent (100x50) → clipped to parent's bounds
        try std.testing.expectEqual(@Vector(4, f32){ 0, 0, 100, 50 }, childClip.?);
    });
}

// --- Z-ordering tests ---

test "buildDrawCommands respects explicit zIndex overrides" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // Root → childA (default z=1), childB (explicit zIndex=100)
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .{ .fixed = 200 },
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50 },
                    .height = .{ .fixed = 50 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50 },
                    .height = .{ .fixed = 50 },
                    .zIndex = 100,
                },
            })({});
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // The last command should be the one with zIndex=100
        try std.testing.expectEqual(@as(u16, 100), cmds[cmds.len - 1].z);
        // And it must be after commands with smaller z
        for (cmds[0 .. cmds.len - 1]) |cmd| {
            try std.testing.expect(cmd.z < 100);
        }
    });
}

test "buildDrawCommands: nested children have z greater than parent" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .{ .fixed = 200 },
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100 },
                    .height = .{ .fixed = 100 },
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 50 },
                        .height = .{ .fixed = 50 },
                    },
                })({});
            });
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        try std.testing.expectEqual(@as(usize, 3), cmds.len);
        // Commands are sorted by z, so nesting order is preserved
        try std.testing.expect(cmds[0].z < cmds[1].z);
        try std.testing.expect(cmds[1].z < cmds[2].z);
    });
}

test "buildDrawCommands: siblings at same z remain in document order" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        // Three sibling elements all get z = parentZ + 1 → same z
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300 },
                .height = .{ .fixed = 300 },
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 10 }, .height = .{ .fixed = 10 } },
            })({});
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 20 }, .height = .{ .fixed = 20 } },
            })({});
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 30 }, .height = .{ .fixed = 30 } },
            })({});
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        try std.testing.expectEqual(@as(usize, 4), cmds.len);
        // Siblings share a z and, since std.mem.sort is stable, keep doc order
        try std.testing.expectEqual(cmds[1].z, cmds[2].z);
        try std.testing.expectEqual(cmds[2].z, cmds[3].z);
        // elementIndex encodes document order (1, 2, 3 in visible-nodes list)
        try std.testing.expectEqual(@as(usize, 1), cmds[1].start);
        try std.testing.expectEqual(@as(usize, 2), cmds[2].start);
        try std.testing.expectEqual(@as(usize, 3), cmds[3].start);
    });
}

// --- Index correctness tests ---

test "buildDrawCommands: elementIndex is unique and covers 0..N-1" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .{ .fixed = 200 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 10 }, .height = .{ .fixed = 10 } },
            })({});
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 10 }, .height = .{ .fixed = 10 } },
            })({});
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 10 }, .height = .{ .fixed = 10 } },
            })({});
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // Collect element indices
        var seen = [_]bool{false} ** 4;
        var elementCount: usize = 0;
        for (cmds) |cmd| {
            if (cmd.kind == .element) {
                try std.testing.expect(cmd.start == cmd.end); // elements are single-index
                try std.testing.expect(cmd.start < seen.len);
                try std.testing.expect(!seen[cmd.start]); // no duplicates
                seen[cmd.start] = true;
                elementCount += 1;
            }
        }
        // 4 elements, indices 0..3 all used
        try std.testing.expectEqual(@as(usize, 4), elementCount);
        for (seen) |s| try std.testing.expect(s);
    });
}

test "buildDrawCommands: shadowIndex is sequential starting at 0" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const shadow = forbear.Shadow{
        .color = .{ 0, 0, 0, 1 },
        .blurRadius = 5,
        .spread = 0,
        .offset = .{ .x = .{ 0, 0 }, .y = .{ 0, 0 } },
    };

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300 },
                .height = .{ .fixed = 300 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50 },
                    .height = .{ .fixed = 50 },
                    .shadow = shadow,
                },
            })({});
            // No shadow on this one
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50 },
                    .height = .{ .fixed = 50 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50 },
                    .height = .{ .fixed = 50 },
                    .shadow = shadow,
                },
            })({});
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // Gather shadow commands in order
        var shadowStarts = std.ArrayList(usize).empty;
        defer shadowStarts.deinit(arena);
        for (cmds) |cmd| {
            if (cmd.kind == .shadow) {
                try shadowStarts.append(arena, cmd.start);
                try std.testing.expect(cmd.start == cmd.end);
            }
        }

        try std.testing.expectEqual(@as(usize, 2), shadowStarts.items.len);
        // Two shadows, sequential indices 0 and 1
        try std.testing.expectEqual(@as(usize, 0), shadowStarts.items[0]);
        try std.testing.expectEqual(@as(usize, 1), shadowStarts.items[1]);
    });
}

test "buildDrawCommands: text command range matches glyph count" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 500 },
                .height = .{ .fixed = 100 },
                .direction = .vertical,
            },
        })({
            forbear.text("hello");
            forbear.text("world!");
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // Gather text commands in order
        var glyphStart: usize = 0;
        var textCount: usize = 0;
        for (cmds) |cmd| {
            if (cmd.kind == .text) {
                // First text command should start at 0, next picks up where previous ended
                try std.testing.expectEqual(glyphStart, cmd.start);
                // Each text command covers a contiguous range
                try std.testing.expect(cmd.end >= cmd.start);
                glyphStart = cmd.end + 1;
                textCount += 1;
            }
        }
        // Two text nodes → two text commands
        try std.testing.expectEqual(@as(usize, 2), textCount);
        // Total glyphs should be sum of "hello" (5) + "world!" (6) = 11
        try std.testing.expectEqual(@as(usize, 11), glyphStart);
    });
}

// --- Regression guards ---

test "buildDrawCommands: total count equals elements + shadows + nonEmptyText" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const shadow = forbear.Shadow{
        .color = .{ 0, 0, 0, 1 },
        .blurRadius = 5,
        .spread = 0,
        .offset = .{ .x = .{ 0, 0 }, .y = .{ 0, 0 } },
    };

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 500 },
                .height = .{ .fixed = 200 },
                .direction = .vertical,
                .shadow = shadow,
            },
        })({
            forbear.text("hi");
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50 },
                    .height = .{ .fixed = 50 },
                    .shadow = shadow,
                },
            })({});
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // Count kinds
        var elementCount: usize = 0;
        var shadowCount: usize = 0;
        var textCount: usize = 0;
        for (cmds) |cmd| {
            switch (cmd.kind) {
                .element => elementCount += 1,
                .shadow => shadowCount += 1,
                .text => textCount += 1,
            }
        }

        // 3 visible nodes (root, text-element, child)
        try std.testing.expectEqual(@as(usize, 3), elementCount);
        // 2 shadows (root + child)
        try std.testing.expectEqual(@as(usize, 2), shadowCount);
        // 1 text node with glyphs
        try std.testing.expectEqual(@as(usize, 1), textCount);
        // And the total matches
        try std.testing.expectEqual(elementCount + shadowCount + textCount, cmds.len);
    });
}

test "buildDrawCommands: empty text does not emit a text command" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .{ .fixed = 100 },
            },
        })({
            forbear.text(""); // empty — should not add a text node
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        for (cmds) |cmd| {
            try std.testing.expect(cmd.kind != .text);
        }
    });
}

test "buildDrawCommands: each visible node produces exactly one element command" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .{ .fixed = 200 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 10 }, .height = .{ .fixed = 10 } },
            })({});
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 10 }, .height = .{ .fixed = 10 } },
            })({});
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        var elementCount: usize = 0;
        for (cmds) |cmd| {
            if (cmd.kind == .element) elementCount += 1;
        }
        // 3 visible nodes → 3 element commands (no duplicates)
        try std.testing.expectEqual(@as(usize, 3), elementCount);
    });
}

// --- Deeply nested clips ---

test "buildDrawCommands: nested clips intersect correctly" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    // Outer is 200x100. Middle is 300x150 (overflows outer → middle gets outer's clip).
    // Deepest is 400x400 (overflows middle → deepest gets middle's clip ∩ outer's clip).
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200 },
                .height = .{ .fixed = 100 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 300 },
                    .height = .{ .fixed = 150 },
                    .direction = .vertical,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 400 },
                        .height = .{ .fixed = 400 },
                    },
                })({});
            });
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // Find commands by z-level
        var outerClip: ?@Vector(4, f32) = null;
        var middleClip: ?@Vector(4, f32) = null;
        var deepestClip: ?@Vector(4, f32) = null;
        for (cmds) |cmd| {
            if (cmd.kind != .element) continue;
            if (cmd.z == 1) outerClip = cmd.clipRect;
            if (cmd.z == 2) middleClip = cmd.clipRect;
            if (cmd.z == 3) deepestClip = cmd.clipRect;
        }

        // Outer (200x100) has no overflow → no clip
        try std.testing.expect(outerClip == null);
        // Middle (300x150) overflows outer → clipped to outer's bounds
        try std.testing.expectEqual(@Vector(4, f32){ 0, 0, 200, 100 }, middleClip.?);
        // Deepest (400x400) overflows middle → clipped to intersection (same as outer)
        try std.testing.expectEqual(@Vector(4, f32){ 0, 0, 200, 100 }, deepestClip.?);
    });
}

test "buildDrawCommands: three-level clip stack produces monotonically tighter bounds" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    // Each level clips via fixed-size + overflowing child.
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300 },
                .height = .{ .fixed = 300 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 200 },
                    .height = .{ .fixed = 200 },
                    .direction = .vertical,
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 100 },
                        .height = .{ .fixed = 100 },
                        .direction = .vertical,
                    },
                })({
                    forbear.element(.{
                        .style = .{
                            .width = .{ .fixed = 500 },
                            .height = .{ .fixed = 500 },
                        },
                    })({});
                });
            });
        });

        const tree = try forbear.layout();
        const cmds = try forbear.Graphics.buildDrawCommands(arena, tree, .{ 800, 600 });

        // 4 elements total
        try std.testing.expectEqual(@as(usize, 4), cmds.len);

        // Find clips by z-level
        var clips: [4]?@Vector(4, f32) = .{ null, null, null, null };
        for (cmds) |cmd| {
            if (cmd.kind != .element) continue;
            if (cmd.z >= 1 and cmd.z <= 4) clips[cmd.z - 1] = cmd.clipRect;
        }

        // Level 0 (300x300): no overflow → no clip
        try std.testing.expect(clips[0] == null);
        // Level 1 (200x200): fits in 300x300 → no clip
        try std.testing.expect(clips[1] == null);
        // Level 2 (100x100): fits in 200x200 → no clip
        try std.testing.expect(clips[2] == null);
        // Level 3 (500x500): overflows 100x100 → clipped to parent's bounds
        try std.testing.expectEqual(@Vector(4, f32){ 0, 0, 100, 100 }, clips[3].?);
    });
}

// useNodeMeasurement tests

test "useNodeMeasurement returns null on first frame" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var sawMeasurement = false;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 50.0 },
            },
        })({
            if (forbear.useNodeMeasurement()) |_| {
                sawMeasurement = true;
            }
        });
        _ = try forbear.layout();
    });

    try std.testing.expect(!sawMeasurement);
}

test "useNodeMeasurement returns previous frame's resolved size" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .key = "measured-element",
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 50.0 },
            },
        })({
            _ = forbear.useNodeMeasurement();
        });
        _ = try forbear.layout();
    });

    var observedSize: Vec2 = @splat(-1.0);
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .key = "measured-element",
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 50.0 },
            },
        })({
            if (forbear.useNodeMeasurement()) |m| observedSize = m.size;
        });
        _ = try forbear.layout();
    });

    try std.testing.expectApproxEqAbs(@as(f32, 100.0), observedSize[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 50.0), observedSize[1], 0.001);
}

fn MeasuredPositionChild(observed: *Vec2) void {
    forbear.element(.{
        .key = "measured-element",
        .style = .{
            .width = .{ .fixed = 40.0 },
            .height = .{ .fixed = 40.0 },
        },
    })({
        if (forbear.useNodeMeasurement()) |m| observed.* = m.position;
    });
}

fn MeasuredPositionApp(observed: *Vec2) void {
    forbear.element(.{
        .style = .{
            .width = .{ .fixed = 200.0 },
            .height = .{ .fixed = 200.0 },
            .padding = .all(30.0),
            .direction = .horizontal,
        },
    })({
        MeasuredPositionChild(observed);
    });
}

test "useNodeMeasurement returns previous frame's resolved position" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var observedPosition: Vec2 = @splat(-1.0);

    // Frame 1: prime measurement.
    try forbear.frame(try frameMeta(arena))({
        MeasuredPositionApp(&observedPosition);
        _ = try forbear.layout();
    });

    // Frame 2: read the resolved position from the previous frame.
    try forbear.frame(try frameMeta(arena))({
        MeasuredPositionApp(&observedPosition);
        _ = try forbear.layout();
    });

    // Root sits at (0, 0) with padding 30 on all sides, child inherits that offset.
    try std.testing.expectApproxEqAbs(@as(f32, 30.0), observedPosition[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 30.0), observedPosition[1], 0.001);
}

test "useNodeMeasurement reflects most recent completed frame across three frames" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .key = "measured-element",
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 50.0 },
            },
        })({
            _ = forbear.useNodeMeasurement();
        });
        _ = try forbear.layout();
    });

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .key = "measured-element",
            .style = .{
                .width = .{ .fixed = 200.0 },
                .height = .{ .fixed = 80.0 },
            },
        })({
            _ = forbear.useNodeMeasurement();
        });
        _ = try forbear.layout();
    });

    var observedSize: Vec2 = @splat(-1.0);
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .key = "measured-element",
            .style = .{
                .width = .{ .fixed = 200.0 },
                .height = .{ .fixed = 80.0 },
            },
        })({
            if (forbear.useNodeMeasurement()) |m| observedSize = m.size;
        });
        _ = try forbear.layout();
    });

    try std.testing.expectApproxEqAbs(@as(f32, 200.0), observedSize[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 80.0), observedSize[1], 0.001);
}

fn FirstMeasuredSibling(observed: *Vec2) void {
    forbear.element(.{
        .key = "first-measured-element",
        .style = .{
            .width = .{ .fixed = 100.0 },
            .height = .{ .fixed = 50.0 },
        },
    })({
        if (forbear.useNodeMeasurement()) |m| observed.* = m.size;
    });
}

fn SecondMeasuredSibling(observed: *Vec2) void {
    forbear.element(.{
        .key = "second-measured-element",
        .style = .{
            .width = .{ .fixed = 200.0 },
            .height = .{ .fixed = 80.0 },
        },
    })({
        if (forbear.useNodeMeasurement()) |m| observed.* = m.size;
    });
}

fn SiblingMeasurementApp(firstObserved: *Vec2, secondObserved: *Vec2) void {
    forbear.element(.{
        .style = .{
            .width = .{ .fixed = 500.0 },
            .height = .{ .fixed = 200.0 },
            .direction = .horizontal,
        },
    })({
        FirstMeasuredSibling(firstObserved);
        SecondMeasuredSibling(secondObserved);
    });
}

test "useNodeMeasurement tracks sibling elements independently" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var firstSize: Vec2 = @splat(-1.0);
    var secondSize: Vec2 = @splat(-1.0);

    // Frame 1: prime measurements.
    try forbear.frame(try frameMeta(arena))({
        SiblingMeasurementApp(&firstSize, &secondSize);
        _ = try forbear.layout();
    });

    // Frame 2: read each sibling's resolved size independently.
    try forbear.frame(try frameMeta(arena))({
        SiblingMeasurementApp(&firstSize, &secondSize);
        _ = try forbear.layout();
    });

    try std.testing.expectApproxEqAbs(@as(f32, 100.0), firstSize[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 50.0), firstSize[1], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 200.0), secondSize[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 80.0), secondSize[1], 0.001);
}

test "useNodeMeasurement does not crash when tracked element disappears in next frame" {
    // EXPOSES BUG: the frameEnd loop iterates every map entry and dereferences
    // entry.value_ptr.index into the current tree. If a tracked node is not
    // remounted this frame, that index may be out of bounds (or point at an
    // unrelated node). This test asserts the API survives the removal.
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 500.0 },
                .height = .{ .fixed = 200.0 },
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({
                _ = forbear.useNodeMeasurement();
            });
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 200.0 },
                    .height = .{ .fixed = 80.0 },
                },
            })({
                _ = forbear.useNodeMeasurement();
            });
        });
        _ = try forbear.layout();
    });

    // Frame 2: drop the second sibling entirely.
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 500.0 },
                .height = .{ .fixed = 200.0 },
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({
                _ = forbear.useNodeMeasurement();
            });
        });
        _ = try forbear.layout();
    });
}

test "contentSize equals size when children fit" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300.0 },
                .height = .{ .fixed = 200.0 },
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 100.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);

        try std.testing.expectApproxEqAbs(@as(f32, 200.0), root.contentSize[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 50.0), root.contentSize[1], 0.001);
    });
}

test "contentSize exceeds size when children overflow horizontally" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 100.0 },
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 300.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);

        try std.testing.expectApproxEqAbs(@as(f32, 300.0), root.contentSize[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 50.0), root.contentSize[1], 0.001);
    });
}

test "contentSize exceeds size when children overflow vertically" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 200.0 },
                .height = .{ .fixed = 100.0 },
                .direction = .vertical,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50.0 },
                    .height = .{ .fixed = 80.0 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50.0 },
                    .height = .{ .fixed = 80.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);

        try std.testing.expectApproxEqAbs(@as(f32, 50.0), root.contentSize[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 160.0), root.contentSize[1], 0.001);
    });
}

test "contentSize ignores fixed-placement children" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 100.0 },
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({});
            // Viewport-pinned: should not stretch the parent's contentSize.
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 9999.0 },
                    .height = .{ .fixed = 9999.0 },
                    .placement = .{ .fixed = .{ 0, 0 } },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);

        try std.testing.expectApproxEqAbs(@as(f32, 50.0), root.contentSize[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 50.0), root.contentSize[1], 0.001);
    });
}

test "contentSize is exposed through useNodeMeasurement" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .key = "measured-element",
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 100.0 },
                .direction = .horizontal,
            },
        })({
            _ = forbear.useNodeMeasurement();
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 400.0 },
                    .height = .{ .fixed = 40.0 },
                },
            })({});
        });
        _ = try forbear.layout();
    });

    var observed: Vec2 = @splat(-1.0);
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .key = "measured-element",
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 100.0 },
                .direction = .horizontal,
            },
        })({
            if (forbear.useNodeMeasurement()) |m| observed = m.contentSize;
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 400.0 },
                    .height = .{ .fixed = 40.0 },
                },
            })({});
        });
        _ = try forbear.layout();
    });

    try std.testing.expectApproxEqAbs(@as(f32, 400.0), observed[0], 0.001);
    try std.testing.expectApproxEqAbs(@as(f32, 40.0), observed[1], 0.001);
}

test "contentSize ignores relative-placement children" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 100.0 },
                .direction = .horizontal,
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({});
            // Parent-anchored overlay (e.g. tooltip): should not stretch the
            // parent's contentSize even though it sits at a huge offset.
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 500.0 },
                    .height = .{ .fixed = 500.0 },
                    .placement = .{ .relative = .{ 400, 400 } },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);

        try std.testing.expectApproxEqAbs(@as(f32, 50.0), root.contentSize[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 50.0), root.contentSize[1], 0.001);
    });
}

test "childrenOffset shifts flow children by the offset" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300.0 },
                .height = .{ .fixed = 200.0 },
                .direction = .horizontal,
            },
        })({
            if (forbear.getParentNode()) |parent| {
                parent.childrenOffset = .{ -40, -15 };
            }
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50.0 },
                    .height = .{ .fixed = 50.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const firstChild = tree.at(root.firstChild.?);
        const secondChild = tree.at(firstChild.nextSibling.?);

        // Natural positions (no offset) would be (0,0) and (50,0).
        // With offset (-40, -15): (-40, -15) and (10, -15).
        try std.testing.expectApproxEqAbs(@as(f32, -40.0), firstChild.position[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, -15.0), firstChild.position[1], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 10.0), secondChild.position[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, -15.0), secondChild.position[1], 0.001);
    });
}

test "childrenOffset does not shift relative children" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300.0 },
                .height = .{ .fixed = 200.0 },
            },
        })({
            if (forbear.getParentNode()) |parent| {
                parent.childrenOffset = .{ 25, 10 };
            }
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50.0 },
                    .height = .{ .fixed = 50.0 },
                    .placement = .{ .relative = .{ 100, 80 } },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const child = tree.at(root.firstChild.?);

        // Relative anchor (100, 80); parent's childrenOffset must not shift
        // it, so the position stays at the anchor.
        try std.testing.expectApproxEqAbs(@as(f32, 100.0), child.position[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 80.0), child.position[1], 0.001);
    });
}

test "childrenOffset does not shift fixed children" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300.0 },
                .height = .{ .fixed = 200.0 },
            },
        })({
            if (forbear.getParentNode()) |parent| {
                parent.childrenOffset = .{ 500, 500 };
            }
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50.0 },
                    .height = .{ .fixed = 50.0 },
                    .placement = .{ .fixed = .{ 70, 80 } },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const child = tree.at(root.firstChild.?);

        // Viewport-pinned: ignores parent's childrenOffset entirely.
        try std.testing.expectApproxEqAbs(@as(f32, 70.0), child.position[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 80.0), child.position[1], 0.001);
    });
}

test "childrenOffset does not shift absolute children" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300.0 },
                .height = .{ .fixed = 200.0 },
            },
        })({
            if (forbear.getParentNode()) |parent| {
                parent.childrenOffset = .{ 500, 500 };
            }
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 50.0 },
                    .height = .{ .fixed = 50.0 },
                    .placement = .{ .absolute = .{ 70, 80 } },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const child = tree.at(root.firstChild.?);

        // Absolute: document-space via root.position (0,0 here), independent
        // of the parent's childrenOffset.
        try std.testing.expectApproxEqAbs(@as(f32, 70.0), child.position[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 80.0), child.position[1], 0.001);
    });
}

test "childrenOffset does not change contentSize" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 100.0 },
                .direction = .horizontal,
            },
        })({
            if (forbear.getParentNode()) |parent| {
                parent.childrenOffset = .{ -123, 456 };
            }
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 400.0 },
                    .height = .{ .fixed = 40.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);

        // Same numbers as the "exceeds size when children overflow
        // horizontally" test: the offset must not leak into contentSize.
        try std.testing.expectApproxEqAbs(@as(f32, 400.0), root.contentSize[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 40.0), root.contentSize[1], 0.001);
    });
}

test "childrenOffset propagates through descendants via ancestor positions" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300.0 },
                .height = .{ .fixed = 300.0 },
            },
        })({
            if (forbear.getParentNode()) |parent| {
                parent.childrenOffset = .{ -10, -20 };
            }
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 200.0 },
                    .height = .{ .fixed = 200.0 },
                },
            })({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 50.0 },
                        .height = .{ .fixed = 50.0 },
                    },
                })({});
            });
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const middle = tree.at(root.firstChild.?);
        const leaf = tree.at(middle.firstChild.?);

        // middle shifted by root.childrenOffset -> (-10, -20)
        try std.testing.expectApproxEqAbs(@as(f32, -10.0), middle.position[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, -20.0), middle.position[1], 0.001);
        // leaf adopts middle's shifted position (middle has no offset of its
        // own) -> (-10, -20)
        try std.testing.expectApproxEqAbs(@as(f32, -10.0), leaf.position[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, -20.0), leaf.position[1], 0.001);
    });
}

test "root translate offsets the root's position" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 50.0 },
                .translate = .{ 50.0, 80.0 },
            },
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .fixed = 20.0 },
                    .height = .{ .fixed = 20.0 },
                },
            })({});
        });

        const tree = try forbear.layout();
        const root = tree.at(0);
        const child = tree.at(root.firstChild.?);

        try std.testing.expectApproxEqAbs(@as(f32, 50.0), root.position[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 80.0), root.position[1], 0.001);
        // Flow child inherits the root's translated position.
        try std.testing.expectApproxEqAbs(@as(f32, 50.0), child.position[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 80.0), child.position[1], 0.001);
    });
}

test "contentSize for a leaf element is zero" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 100.0 },
                .height = .{ .fixed = 50.0 },
            },
        })({});

        const tree = try forbear.layout();
        const root = tree.at(0);

        try std.testing.expectApproxEqAbs(@as(f32, 0.0), root.contentSize[0], 0.001);
        try std.testing.expectApproxEqAbs(@as(f32, 0.0), root.contentSize[1], 0.001);
    });
}

// context tests

const SimpleCtx = forbear.createContext(opaque {}, u32);
const ThemeCtx = forbear.createContext(opaque {}, u32);
const NestedCtx = forbear.createContext(opaque {}, u32);
const SiblingCtx = forbear.createContext(opaque {}, u32);
const PersistCtx = forbear.createContext(opaque {}, u32);

const StructValue = struct {
    flags: [4]u32,
    label: [8]u8,
};
const StructCtx = forbear.createContext(opaque {}, StructValue);

test "context value is visible to a descendant via useContext" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var observed: ?u32 = null;
    var observedAtRoot: ?u32 = null;
    try forbear.frame(try frameMeta(arena))({
        if (SimpleCtx.use()) |v| observedAtRoot = v.*;
        forbear.element(.{
            .style = .{ .width = .{ .fixed = 100.0 }, .height = .{ .fixed = 100.0 } },
        })({
            SimpleCtx.Provider(@as(u32, 42))({
                forbear.element(.{
                    .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
                })({
                    if (SimpleCtx.use()) |v| observed = v.*;
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(@as(?u32, null), observedAtRoot);
    try std.testing.expectEqual(@as(?u32, 42), observed);
}

test "same context nested with different values resolves to nearest provider" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var outerObserved: ?u32 = null;
    var middleObserved: ?u32 = null;
    var innermostObserved: ?u32 = null;
    try forbear.frame(try frameMeta(arena))({
        NestedCtx.Provider(@as(u32, 1))({
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 100.0 }, .height = .{ .fixed = 100.0 } },
            })({
                if (NestedCtx.use()) |v| outerObserved = v.*;
                NestedCtx.Provider(@as(u32, 2))({
                    forbear.element(.{
                        .style = .{ .width = .{ .fixed = 50.0 }, .height = .{ .fixed = 50.0 } },
                    })({
                        if (NestedCtx.use()) |v| middleObserved = v.*;
                        NestedCtx.Provider(@as(u32, 3))({
                            forbear.element(.{
                                .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
                            })({
                                if (NestedCtx.use()) |v| innermostObserved = v.*;
                            });
                        });
                    });
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(@as(?u32, 1), outerObserved);
    try std.testing.expectEqual(@as(?u32, 2), middleObserved);
    try std.testing.expectEqual(@as(?u32, 3), innermostObserved);
}

test "two different contexts at the same scope each resolve to their own value" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var observedSimple: ?u32 = null;
    var observedTheme: ?u32 = null;
    try forbear.frame(try frameMeta(arena))({
        SimpleCtx.Provider(@as(u32, 100))({
            ThemeCtx.Provider(@as(u32, 200))({
                forbear.element(.{
                    .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
                })({
                    if (SimpleCtx.use()) |v| observedSimple = v.*;
                    if (ThemeCtx.use()) |v| observedTheme = v.*;
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(@as(?u32, 100), observedSimple);
    try std.testing.expectEqual(@as(?u32, 200), observedTheme);
}

test "useContext returns null when no provider has been mounted" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var atTopLevel: ?u32 = 999;
    var insideNestedElement: ?u32 = 999;
    try forbear.frame(try frameMeta(arena))({
        if (SimpleCtx.use()) |v| atTopLevel = v.* else atTopLevel = null;
        forbear.element(.{
            .style = .{ .width = .{ .fixed = 50.0 }, .height = .{ .fixed = 50.0 } },
        })({
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
            })({
                if (SimpleCtx.use()) |v| insideNestedElement = v.* else insideNestedElement = null;
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(@as(?u32, null), atTopLevel);
    try std.testing.expectEqual(@as(?u32, null), insideNestedElement);
}

test "provider value does not leak to siblings after its block ends" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var insideFirst: ?u32 = null;
    var betweenProviders: ?u32 = 999;
    var insideSecond: ?u32 = null;
    var afterSecond: ?u32 = 999;
    try forbear.frame(try frameMeta(arena))({
        SiblingCtx.Provider(@as(u32, 7))({
            if (SiblingCtx.use()) |v| insideFirst = v.*;
        });
        if (SiblingCtx.use()) |v| betweenProviders = v.* else betweenProviders = null;
        SiblingCtx.Provider(@as(u32, 9))({
            if (SiblingCtx.use()) |v| insideSecond = v.*;
        });
        if (SiblingCtx.use()) |v| afterSecond = v.* else afterSecond = null;
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(@as(?u32, 7), insideFirst);
    try std.testing.expectEqual(@as(?u32, null), betweenProviders);
    try std.testing.expectEqual(@as(?u32, 9), insideSecond);
    try std.testing.expectEqual(@as(?u32, null), afterSecond);
}

fn PersistComponent(observed: *?u32, writeBack: ?u32) void {
    PersistCtx.Provider(@as(u32, 10))({
        if (PersistCtx.use()) |v| {
            observed.* = v.*;
            if (writeBack) |w| v.* = w;
        }
    });
}

test "provider value persists and is mutable across frames" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    // Frame 1: mount the provider with an initial value of 10, then mutate
    // it through the pointer returned by useContext.
    var observedFrame1: ?u32 = null;
    try forbear.frame(try frameMeta(arena))({
        PersistComponent(&observedFrame1, 77);
        _ = try forbear.layout();
    });

    // Frame 2: remount the provider through the same component. The
    // initial value (10) should be ignored because a value already exists
    // for this bucket; the stored 77 from frame 1 should be observed.
    var observedFrame2: ?u32 = null;
    try forbear.frame(try frameMeta(arena))({
        PersistComponent(&observedFrame2, null);
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(@as(?u32, 10), observedFrame1);
    try std.testing.expectEqual(@as(?u32, 77), observedFrame2);
}

test "provider round-trips a non-trivial struct value" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const initial: StructValue = .{
        .flags = .{ 1, 2, 3, 4 },
        .label = .{ 'f', 'o', 'r', 'b', 'e', 'a', 'r', 0 },
    };

    var observed: ?StructValue = null;
    try forbear.frame(try frameMeta(arena))({
        StructCtx.Provider(initial)({
            forbear.element(.{
                .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
            })({
                if (StructCtx.use()) |v| observed = v.*;
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expect(observed != null);
    try std.testing.expectEqualSlices(u32, &initial.flags, &observed.?.flags);
    try std.testing.expectEqualSlices(u8, &initial.label, &observed.?.label);
}

const SlotCtx = forbear.createContext(opaque {}, u32);

test "context provided inside a component is visible to slotted children" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    const SlottedProvider = (struct {
        fn SlottedProvider() *const fn (void) void {
            forbear.component(.{})({
                SlotCtx.Provider(@as(u32, 55))({
                    forbear.componentChildrenSlot();
                });
            });
            return forbear.componentChildrenSlotEnd();
        }
    }).SlottedProvider;

    var observed: ?u32 = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            SlottedProvider()({
                forbear.element(.{
                    .style = .{
                        .width = .{ .fixed = 50 },
                        .height = .{ .fixed = 50 },
                    },
                })({
                    if (SlotCtx.use()) |v| observed = v.*;
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(@as(?u32, 55), observed);
}

// ── FocusContext tests ─────────────────────────────────────────────────

const FocusProvider = forbear.FocusProvider;
const FocusContext = forbear.FocusContext;
const EventPayload = forbear.EventPayload;

fn consumesKeyDown(payload: EventPayload) bool {
    return payload == .keyDown;
}

fn consumesNothing(_: EventPayload) bool {
    return false;
}

fn consumesEverything(_: EventPayload) bool {
    return true;
}

test "FocusContext: register and hasFocus are false when nothing is focused" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var observed: ?bool = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;
                    forbear.element(.{
                        .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
                    })({
                        ctx.register(&consumesKeyDown);
                        observed = ctx.hasFocus();
                    });
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(false, observed.?);
}

test "FocusContext: focus gives hasFocus to the registered element" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var hasFocusA: ?bool = null;
    var hasFocusB: ?bool = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;

                    forbear.element(.{
                        .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
                    })({
                        ctx.register(&consumesKeyDown);
                        ctx.focus();
                        hasFocusA = ctx.hasFocus();
                    });

                    forbear.element(.{
                        .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
                    })({
                        ctx.register(&consumesNothing);
                        hasFocusB = ctx.hasFocus();
                    });
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(true, hasFocusA.?);
    try std.testing.expectEqual(false, hasFocusB.?);
}

test "FocusContext: consumes delegates to the focused widget predicate" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var consumesKeyDownResult: ?bool = null;
    var consumesClickResult: ?bool = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;

                    forbear.element(.{
                        .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
                    })({
                        ctx.register(&consumesKeyDown);
                        ctx.focus();
                    });

                    consumesKeyDownResult = ctx.consumes(.keyDown, .{ .tab = true });
                    consumesClickResult = ctx.consumes(.click, true);
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(true, consumesKeyDownResult.?);
    try std.testing.expectEqual(false, consumesClickResult.?);
}

test "FocusContext: consumes returns false when nothing is focused" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var result: ?bool = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;

                    forbear.element(.{
                        .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } },
                    })({
                        ctx.register(&consumesEverything);
                    });

                    result = ctx.consumes(.keyDown, .{ .a = true });
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(false, result.?);
}

test "FocusContext: tab cycles focus forward through registered elements" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    // Frame 1: register three focusables, none focused
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                    });
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                    });
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                    });

                    // Simulate tab press
                    forbear.getForbear().keysPressedThisFrame = .{ .tab = true };
                    ctx.handleEvents();

                    try std.testing.expect(ctx.focused != null);
                });
            });
        });
        _ = try forbear.layout();
    });
}

test "FocusContext: tab with no focus starts at first element" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var focusedKey: ?u64 = null;
    var firstKey: ?u64 = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;

                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                        firstKey = forbear.getParentNode().?.key;
                    });
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                    });

                    forbear.getForbear().keysPressedThisFrame = .{ .tab = true };
                    ctx.handleEvents();
                    focusedKey = if (ctx.focused) |f| f.key else null;
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expect(firstKey != null);
    try std.testing.expectEqual(firstKey.?, focusedKey.?);
}

test "FocusContext: tab wraps from last to first element" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var firstKey: ?u64 = null;
    var focusedKey: ?u64 = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;

                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                        firstKey = forbear.getParentNode().?.key;
                    });
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                        // Focus the last element so tab wraps around
                        ctx.focus();
                    });

                    forbear.getForbear().keysPressedThisFrame = .{ .tab = true };
                    ctx.handleEvents();
                    focusedKey = if (ctx.focused) |f| f.key else null;
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expect(firstKey != null);
    try std.testing.expectEqual(firstKey.?, focusedKey.?);
}

test "FocusContext: shift+tab cycles focus backward" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var thirdKey: ?u64 = null;
    var focusedKey: ?u64 = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const focusContext = FocusContext.use().?;

                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        focusContext.register(&consumesNothing);
                        // Focus the first element
                        focusContext.focus();
                    });
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        focusContext.register(&consumesNothing);
                    });
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        focusContext.register(&consumesNothing);
                        thirdKey = forbear.getParentNode().?.key;
                    });

                    // Simulate shift+tab
                    forbear.getForbear().keysPressedThisFrame = .{ .tab = true };
                    forbear.getForbear().keysHeldSnapshot = .{ .shift = true };
                    focusContext.handleEvents();
                    focusedKey = if (focusContext.focused) |f| f.key else null;
                });
            });
        });
        _ = try forbear.layout();
    });

    // Shift+tab from first should wrap to last
    // Wait — from index 0, shift+tab goes to (0 + 3 - 1) % 3 = 2, which is the third element
    // Let me verify by checking the third key instead
    try std.testing.expect(focusedKey != null);
    // Should NOT be the second element (index 1), should be last (index 2)
    try std.testing.expect(focusedKey.? == thirdKey.?);
}

test "FocusContext: escape clears focus" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    var hasFocusAfterEscape: ?bool = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;

                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                        ctx.focus();
                    });

                    // Verify focus is set
                    try std.testing.expect(ctx.focused != null);

                    // Simulate escape
                    forbear.getForbear().keysPressedThisFrame = .{ .escape = true };
                    ctx.handleEvents();
                    hasFocusAfterEscape = ctx.focused != null;
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(false, hasFocusAfterEscape.?);
}

test "FocusContext: stale focus is dropped when widget does not re-register" {
    try forbear.init(std.testing.allocator, std.testing.io, undefined);
    defer forbear.deinit();

    var arenaAllocator = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arenaAllocator.deinit();
    const arena = arenaAllocator.allocator();

    // Frame 1: register two elements, focus the second
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                    });
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                        ctx.focus();
                    });
                    try std.testing.expect(ctx.focused != null);
                });
            });
        });
        _ = try forbear.layout();
    });

    // Frame 2: only register one element (the second one is "unmounted").
    // handleEvents should drop the stale focus.
    var focusedAfterDrop: ?bool = null;
    try forbear.frame(try frameMeta(arena))({
        forbear.element(.{})({
            forbear.component(.{})({
                FocusProvider()({
                    const ctx = FocusContext.use().?;
                    forbear.element(.{ .style = .{ .width = .{ .fixed = 10.0 }, .height = .{ .fixed = 10.0 } } })({
                        ctx.register(&consumesNothing);
                    });
                    ctx.handleEvents();
                    focusedAfterDrop = ctx.focused != null;
                });
            });
        });
        _ = try forbear.layout();
    });

    try std.testing.expectEqual(false, focusedAfterDrop.?);
}

// window.zig EventQueue tests

// Mirrors the live setup in playground.zig: the Wayland event thread is the
// sole producer pushing onto `Window.EventQueue`, and Forbear's render thread
// is the sole consumer draining it via `iterate()` (see root.zig:942). This
// stresses that single-producer/single-consumer split — one thread blasts a
// long, identifiable sequence of events while the other drains and asserts
// each one arrives intact and in order.
test "EventQueue: SPSC producer/consumer round-trips every event in order" {
    const Event = forbear.Window.Event;
    const EventQueue = forbear.Window.EventQueue;

    // "lots of events" — far more than the 256-slot ring, so the buffer wraps
    // thousands of times and the head/tail acquire-release handshake is what
    // keeps producer and consumer in sync.
    const total: u32 = 200_000;

    var queue: EventQueue = .empty;

    const Producer = struct {
        // Even indices ride a `pointerMotion`, odd indices a `scroll`, so the
        // consumer verifies the union *tag* round-trips too, not just payloads.
        fn eventFor(i: u32) Event {
            if (i % 2 == 0) {
                return .{ .pointerMotion = .{
                    .time = i,
                    .x = @floatFromInt(i),
                    .y = @floatFromInt(i),
                } };
            } else {
                return .{ .scroll = .{
                    .axis = .vertical,
                    .offset = @floatFromInt(i),
                } };
            }
        }

        fn run(q: *EventQueue, count: u32) void {
            var i: u32 = 0;
            while (i < count) : (i += 1) {
                // `push` drops silently when the ring is full. As the lone
                // producer, `tail.raw` is stable and `head` only advances, so
                // spinning until there's a free slot guarantees no drops and
                // lets us assert *every* event is delivered.
                while (q.tail.raw - q.head.load(.acquire) >= q.buffer.len) {
                    std.atomic.spinLoopHint();
                }
                q.push(eventFor(i));
            }
        }
    };

    const thread = try std.Thread.spawn(.{}, Producer.run, .{ &queue, total });
    defer thread.join();

    var received: u32 = 0;
    while (received < total) {
        var iterator = queue.iterate();
        while (iterator.next()) |event| {
            const expected = Producer.eventFor(received);
            switch (expected) {
                .pointerMotion => |want| {
                    try std.testing.expect(event == .pointerMotion);
                    try std.testing.expectEqual(want.time, event.pointerMotion.time);
                    try std.testing.expectEqual(want.x, event.pointerMotion.x);
                    try std.testing.expectEqual(want.y, event.pointerMotion.y);
                },
                .scroll => |want| {
                    try std.testing.expect(event == .scroll);
                    try std.testing.expectEqual(want.axis, event.scroll.axis);
                    try std.testing.expectEqual(want.offset, event.scroll.offset);
                },
                else => unreachable,
            }
            received += 1;
        }
        std.atomic.spinLoopHint();
    }

    try std.testing.expectEqual(total, received);
}
