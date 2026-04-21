const forbear = @import("forbear");
const Colors = @import("../colors.zig");

pub fn JonQuote() !void {
    forbear.element(.{
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .xJustification = .center,
        .yJustification = .start,
        .padding = forbear.Padding.top(15.0).withBottom(30.0),
    })({
        forbear.element(.{
            .direction = .horizontal,
        })({
            forbear.image(.{
                .width = .{ .fixed = 150.0 },
                .height = .{ .fixed = 150.0 },
                .margin = forbear.Margin.inLine(0.0).withRight(12.0),
            }, try forbear.useImage("uhoh-jon-avatar"));
            forbear.element(.{
                .direction = .vertical,
            })({
                forbear.element(.{
                    .fontSize = 13.5,
                    .lineHeight = 1.4,
                })({
                    forbear.text("I literally built this because I needed it for myself... it has to be fast, incredibly good and insanely affordable. It's usually impossible to get all three, but we figured it out and we're willing to go to great lengths to let you experience that for yourself.");
                });
                forbear.element(.{
                    .fontSize = 10.5,
                    .color = Colors.muted,
                    .margin = forbear.Margin.block(9.0).withBottom(0.0),
                })({
                    forbear.text("- Jon Sturgeon, CEO of Dingus & Zazzy & Co-Founder of uhoh");
                });
            });
        });
    });
}
