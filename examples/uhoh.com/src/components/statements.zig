const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;

fn Statement(style: forbear.Style, text: []const u8) !void {
    forbear.component(.{})({
        forbear.element(.{
            .style = style.overwrite(.{
                .direction = .horizontal,
                .xJustification = .start,
                .yJustification = .center,
                .width = .{ .grow = 1.0 },
            }),
        })({
            forbear.Image(.{
                .width = .{ .fixed = 30.0 },
                .height = .{ .fixed = 30.0 },
                .blendMode = .multiply,
                .margin = .right(15.0),
            }, try forbear.useImage("uhoh-check"));
            forbear.text(text);
        });
    });
}

pub fn Statements() !void {
    forbear.component(.{})({
        Section(.{
            .yJustification = .start,
            .padding = .block(30.0),
            .borderWidth = .block(2.0),
            .borderColor = colors.black,
        })({
            try Statement(.{}, "Less problems, more productivity");
            try Statement(.{ .padding = .left(20.0) }, "Your team runs smoother");
            try Statement(.{ .padding = .left(20.0) }, "A hundred things less on your plate");
        });
    });
}
