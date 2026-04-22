const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;

pub fn Solution() !void {
    Section(.{
        .direction = .vertical,
    })({
        forbear.image(.{
            .width = .{ .grow = 1.0 },
            .maxWidth = 600,
            .blendMode = .multiply,
        }, try forbear.useImage("uhoh-solution"));
        forbear.element(.{
            .fontWeight = 700,
            .maxWidth = 630.0,
            .width = .{ .grow = 1.0 },
            .xJustification = .center,
            .direction = .vertical,
        })({
            forbear.element(.{
                .xJustification = .center,
                .fontSize = 40.0,
                .margin = forbear.Margin.top(20.0).withBottom(25.0),
            })({
                forbear.text("We're here to reinvent how tech gets done.");
            });
            forbear.text("We're replacing clunky IT with clean, fast, and flexible support. Built for startups and teams that just want things to work.");
        });
    });
}
