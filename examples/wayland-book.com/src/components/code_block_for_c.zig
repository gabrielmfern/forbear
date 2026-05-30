const std = @import("std");
const forbear = @import("forbear");
const ts = @import("tree-sitter");
const tsC = @import("tree-sitter-c");

const Vec4 = @Vector(4, f32);

// A tiny GitHub-light-ish theme. Just enough that C reads as code instead of a
// single wall of colour.
const Theme = struct {
    const default = forbear.hex("24292e");
    const keyword = forbear.hex("d73a49");
    const typeName = forbear.hex("6f42c1");
    const string = forbear.hex("032f62");
    const number = forbear.hex("005cc5");
    const comment = forbear.hex("6a737d");
    const preproc = forbear.hex("d73a49");
};

const Span = struct {
    text: []const u8,
    color: Vec4,
};

const Line = std.ArrayList(Span);

// Walks the parse tree leaf-first, mapping node types to theme colours, and
// collects a per-line list of coloured spans. Whitespace and any bytes the tree
// doesn't cover are emitted in the default colour so indentation survives.
const Highlighter = struct {
    arena: std.mem.Allocator,
    source: []const u8,
    lines: std.ArrayList(Line),
    pos: u32 = 0,

    fn line(self: *Highlighter) *Line {
        return &self.lines.items[self.lines.items.len - 1];
    }

    // Append text in a colour, breaking into new lines on every '\n'.
    fn emit(self: *Highlighter, text: []const u8, color: Vec4) !void {
        var rest = text;
        while (std.mem.indexOfScalar(u8, rest, '\n')) |nl| {
            if (nl > 0) try self.line().append(self.arena, .{ .text = rest[0..nl], .color = color });
            try self.lines.append(self.arena, .empty);
            rest = rest[nl + 1 ..];
        }
        if (rest.len > 0) try self.line().append(self.arena, .{ .text = rest, .color = color });
    }

    // Fill the gap between the last emitted byte and `until` (whitespace, etc.).
    fn gapTo(self: *Highlighter, until: u32) !void {
        if (until > self.pos) try self.emit(self.source[self.pos..until], Theme.default);
    }

    fn walk(self: *Highlighter, node: ts.TSNode) !void {
        const name = std.mem.span(ts.ts_node_type(node));
        const start = ts.ts_node_start_byte(node);
        const end = ts.ts_node_end_byte(node);

        // Colour strings/comments whole; don't descend into their quotes/escapes.
        if (wholeColor(name)) |color| {
            try self.gapTo(start);
            try self.emit(self.source[start..end], color);
            self.pos = end;
            return;
        }

        const childCount = ts.ts_node_child_count(node);
        if (childCount == 0) {
            try self.gapTo(start);
            try self.emit(self.source[start..end], leafColor(name, ts.ts_node_is_named(node)));
            self.pos = end;
            return;
        }

        var i: u32 = 0;
        while (i < childCount) : (i += 1) {
            try self.walk(ts.ts_node_child(node, i));
        }
    }
};

fn wholeColor(name: []const u8) ?Vec4 {
    if (std.mem.indexOf(u8, name, "comment") != null) return Theme.comment;
    if (std.mem.indexOf(u8, name, "string") != null) return Theme.string;
    if (std.mem.eql(u8, name, "char_literal")) return Theme.string;
    return null;
}

fn leafColor(name: []const u8, named: bool) Vec4 {
    if (name.len == 0) return Theme.default;
    if (std.mem.eql(u8, name, "number_literal")) return Theme.number;
    if (named) {
        // type_identifier, primitive_type ("int"), sized_type_specifier, etc.
        if (std.mem.eql(u8, name, "primitive_type") or
            std.mem.eql(u8, name, "type_identifier") or
            std.mem.eql(u8, name, "sized_type_specifier"))
            return Theme.typeName;
        return Theme.default; // identifiers, field names, ...
    }
    // Anonymous tokens: a leading letter is a keyword (return, if, struct, ...),
    // a leading '#' is a preprocessor directive, anything else is punctuation.
    return switch (name[0]) {
        '#' => Theme.preproc,
        'a'...'z' => Theme.keyword,
        else => Theme.default,
    };
}

fn highlight(arena: std.mem.Allocator, source: []const u8) !std.ArrayList(Line) {
    const parser = ts.ts_parser_new();
    defer ts.ts_parser_delete(parser);
    _ = ts.ts_parser_set_language(parser, @ptrCast(tsC.language()));

    const tree = ts.ts_parser_parse_string(parser, null, source.ptr, @intCast(source.len));
    defer ts.ts_tree_delete(tree);

    var highlighter: Highlighter = .{ .arena = arena, .source = source, .lines = .empty };
    try highlighter.lines.append(arena, .empty);
    try highlighter.walk(ts.ts_tree_root_node(tree));
    try highlighter.gapTo(@intCast(source.len));
    return highlighter.lines;
}

// Renders `source` as a syntax-highlighted C code block, matching how
// wayland-book.com styles its code: 1rem padding on a #f4f4f4 background.
pub fn CodeBlockForC(source: []const u8) void {
    const arena = forbear.useArena();
    const font = forbear.useFont("Source Code Pro") catch null;
    const lines = highlight(arena, source) catch return;

    forbear.element(.{
        .style = .{
            .width = .{ .grow = 1.0 },
            .direction = .vertical,
            .background = .{ .color = forbear.hex("f4f4f4") },
            .borderRadius = 3.0,
            .padding = .all(16.0),
            .margin = .bottom(16.0),
            .font = font,
            .fontSize = 14.0,
            .color = Theme.default,
            .textWrapping = .none,
            .lineHeight = 1.5,
        },
    })({
        for (lines.items) |spans| {
            forbear.composeText(.{})({
                if (spans.items.len == 0) {
                    forbear.write(" "); // keep blank lines as tall as a glyph
                } else {
                    for (spans.items) |span| {
                        forbear.textStyle(.{ .color = span.color })({
                            forbear.write(span.text);
                        });
                    }
                }
            });
        }
    });
}
