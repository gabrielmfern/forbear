const forbear = @import("forbear");
const colors = @import("../colors.zig");

pub fn Footer() !void {
    forbear.element(.{
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .xJustification = .center,
        .yJustification = .start,
        .padding = forbear.Padding.top(15.0).withBottom(19.5),
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
