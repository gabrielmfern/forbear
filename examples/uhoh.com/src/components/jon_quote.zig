const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Section = @import("section.zig").Section;

pub fn JonQuote() !void {
    forbear.component(.{})({
        Section(.{
            .yJustification = .start,
            .margin = .top(40),
        })({
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .direction = .horizontal,
                    .borderRadius = 12.0,
                    .borderWidth = .all(2.0),
                    .borderColor = colors.black,
                    .background = .{ .color = forbear.white },
                    .padding = .all(35.0),
                    .yJustification = .center,
                },
            })({
                forbear.Image(.{
                    .width = .{ .fixed = 200.0 },
                    .margin = .right(40.0),
                }, try forbear.useImage("uhoh-jon-avatar"));
                forbear.element(.{
                    .style = .{
                        .direction = .vertical,
                        .width = .{ .grow = 1.0 },
                    },
                })({
                    forbear.element(.{
                        .style = .{
                            .fontSize = 32.0,
                            .lineHeight = 1.0,
                            .margin = .bottom(20.0),
                        },
                    })({
                        forbear.text("“I literally built this because I needed it for myself… it has to be fast, incredibly good and insanely affordable. It's usually impossible to get all three, but we figured it out and we're willing to go to great lengths to let you experience that for yourself.”");
                    });
                    forbear.text("- Jon Sturgeon, CEO of Dingus & Zazzy");
                    forbear.text("& Co-Founder of uhoh");
                });
            });
        });
    });
}
