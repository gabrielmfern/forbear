const forbear = @import("forbear");
const colors = @import("../colors.zig");

fn Statement(style: forbear.Style, text: []const u8) !void {
    forbear.element(style.overwrite(.{
        .direction = .horizontal,
        .xJustification = .start,
        .yJustification = .center,
        .width = .{ .grow = 1.0 },
    }))({
        forbear.image(.{
            .width = .{ .fixed = 30.0 },
            .height = .{ .fixed = 30.0 },
            .blendMode = .multiply,
            .margin = .right(15.0),
        }, try forbear.useImage("uhoh-check"));
        forbear.text(text);
    });
}

pub fn Statements() !void {
    forbear.element(.{
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .xJustification = .center,
        .yJustification = .start,
        .padding = .block(30.0),
        .margin = .block(48.0),
        .borderWidth = .block(2.0),
        .borderColor = colors.black,
    })({
        try Statement(.{}, "Less problems, more productivity");
        try Statement(.{ .padding = .left(20.0) }, "Your team runs smoother");
        try Statement(.{ .padding = .left(20.0) }, "A hundred things less on your plate");
    });
}
