const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Button = @import("button.zig").Button;
const Section = @import("section.zig").Section;

pub fn BottomCta() !void {
    forbear.component(@src())({
        Section(.{})({
            forbear.element(.{ .style = .{
                .direction = .vertical,
                .xJustification = .center,
            } })({
                forbear.Image(.{
                    .height = .{ .fixed = 200.0 },
                    .blendMode = .multiply,
                }, try forbear.useImage("uhoh-bottom-cta"));
                forbear.element(.{ .style = .{
                    .fontWeight = 700,
                    .fontSize = 40.0,
                    .margin = forbear.Margin.top(20.0).withBottom(25.0),
                    .textWrapping = .none,
                    .xJustification = .center,
                } })({
                    forbear.text("Dude, you're at the bottom of our landing page.");
                });
                forbear.element(.{ .style = .{
                    .direction = .vertical,
                    .xJustification = .center,
                } })({
                    forbear.text("Just get the free trial already if you're that interested.");
                    forbear.text("You scrolled all the way here.");
                });

                Button(.{
                    .sizing = .large,
                    .style = .{
                        .margin = .top(40.0),
                    },
                })({
                    forbear.text("Come on, click on this");
                    forbear.element(.{ .style = .{
                        .fontSize = 14.0,
                    } })({
                        forbear.text("Don't make me beg");
                    });
                });
            });
        });
    });
}
