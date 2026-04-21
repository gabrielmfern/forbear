const forbear = @import("forbear");
const colors = @import("../colors.zig");

pub fn Solution() !void {
    forbear.element(.{
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .xJustification = .center,
        .padding = forbear.Padding.top(22.5).withBottom(30.0),
        .direction = .vertical,
    })({
        forbear.image(.{
            .width = .{ .grow = 1.0 },
            .maxWidth = 600,
            .blendMode = .multiply,
        }, try forbear.useImage("uhoh-solution"));
        forbear.element(.{
            .fontWeight = 700,
            .fontSize = 22.5,
            .margin = forbear.Margin.block(13.5).withBottom(7.5),
        })({
            forbear.text("We're here to reinvent how tech gets done.");
        });
        forbear.element(.{
            .fontSize = 12.0,
            .xJustification = .center,
        })({
            forbear.text("We're replacing clunky IT with clean, fast, and flexible support. Built for startups and teams that just want things to work.");
        });
    });
}
