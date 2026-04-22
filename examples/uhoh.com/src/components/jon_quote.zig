const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;

pub fn JonQuote() !void {
    Section(.{
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
                    .margin = forbear.Margin.block(9.0).withBottom(0.0),
                })({
                    forbear.text("- Jon Sturgeon, CEO of Dingus & Zazzy & Co-Founder of uhoh");
                });
            });
        });
    });
}
