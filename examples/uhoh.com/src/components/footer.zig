const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;

pub fn Footer() !void {
    Section(.{ .direction = .vertical })({
        forbear.element(.{
            .width = .{ .grow = 1.0 },
            .padding = .all(35.0),
            .borderWidth = .all(2.0),
            .borderColor = colors.black,
            .borderRadius = 12.0,
            .direction = .vertical,
        })({
            forbear.element(.{
                .yJustification = .center,
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
                .margin = .bottom(69.0),
            })({
                forbear.image(.{
                    .width = .{ .fixed = 90.0 },
                }, try forbear.useImage("uhoh-logo"));

                forbear.element(.{ .width = .{ .grow = 1.0 } })({});

                forbear.element(.{ .fontSize = 12.0, .lineHeight = 1.3 })({
                    forbear.text("Privacy Policy");
                });
            });
            forbear.element(.{
                .yJustification = .center,
                .width = .{ .grow = 1.0 },
                .height = .{ .grow = 1.0 },
            })({
                forbear.element(.{ .fontSize = 12.0, .lineHeight = 1.3 })({
                    forbear.text("© 2025 uhoh. All rights reserved.");
                });

                forbear.element(.{ .width = .{ .grow = 1.0 } })({});

                forbear.element(.{ .fontSize = 12.0, .lineHeight = 1.3 })({
                    forbear.text("Designed by your lover, Loogart");
                });
            });
        });
    });
}
