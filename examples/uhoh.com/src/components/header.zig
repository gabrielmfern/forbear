const forbear = @import("forbear");
const Button = @import("button.zig").Button;
const Section = @import("section.zig").Section;

pub fn Header() !void {
    forbear.element(.{
        .minHeight = 72.0,
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .padding = .inLine(15.0),
        .yJustification = .center,
    })({
        forbear.image(.{
            .width = .{ .fixed = 100.0 },
            .margin = forbear.Margin.right(24.0),
        }, try forbear.useImage("uhoh-logo"));
        forbear.element(.{
            .width = .{ .grow = 1.0 },
            .background = .{ .color = .{ 1.0, 0.0, 0.0, 1.0 } },
        })({});
        forbear.element(.{
            .fontWeight = 500,
            .margin = .right(16.0),
            .padding = .all(20.0),
            .cursor = .pointer,
        })({
            forbear.text("Pricing");
        });
        Button(.{})({
            forbear.text("Try it risk-free");
        });
    });
}
