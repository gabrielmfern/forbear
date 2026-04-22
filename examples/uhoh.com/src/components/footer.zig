const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;

pub fn Footer() !void {
    Section(.{
        .yJustification = .start,
    })({
        forbear.element(.{
            .direction = .vertical,
        })({
            forbear.element(.{
                .direction = .horizontal,
                .xJustification = .center,
                .yJustification = .center,
            })({
                forbear.image(.{
                    .width = .{ .fixed = 90.0 },
                    .margin = forbear.Margin.right(9.0),
                }, try forbear.useImage("uhoh-logo"));
                forbear.element(.{ .fontSize = 9.0 })({
                    forbear.text("Privacy Policy");
                });
            });
            forbear.element(.{
                .direction = .horizontal,
                .margin = forbear.Margin.block(12.0).withBottom(0.0),
            })({
                forbear.element(.{
                    .fontSize = 9.0,
                    .margin = forbear.Margin.inLine(0.0).withRight(15.0),
                })({
                    forbear.text("© 2025 uhoh. All rights reserved.");
                });
                forbear.element(.{
                    .fontSize = 9.0,
                })({
                    forbear.text("Designed by your lover, Loogart");
                });
            });
        });
    });
}
