const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Button = @import("button.zig").Button;
const Section = @import("section.zig").Section;

pub fn BottomCta() !void {
    Section(.{
        .yJustification = .start,
        .padding = forbear.Padding.top(22.5).withBottom(37.5),
    })({
        forbear.element(.{
            .direction = .vertical,
            .xJustification = .center,
            .yJustification = .start,
        })({
            forbear.image(.{
                .height = .{ .fixed = 200.0 },
                .blendMode = .multiply,
            }, try forbear.useImage("uhoh-bottom-cta"));
            forbear.element(.{
                .fontWeight = 700,
                .fontSize = 22.5,
                .margin = forbear.Margin.block(13.5).withBottom(7.5),
            })({
                forbear.text("Dude, you're at the bottom of our landing page.");
            });
            forbear.element(.{
                .fontSize = 12.0,
                .margin = forbear.Margin.block(0.0).withBottom(20.0),
            })({
                forbear.text("Just get the free trial already if you're that interested. You scrolled all the way here.");
            });

            Button(.{})({
                forbear.text("Come on, click on this");
                forbear.element(.{
                    .fontSize = 14.0,
                })({
                    forbear.text("Don't make me beg");
                });
            });
        });
    });
}
