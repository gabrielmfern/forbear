const forbear = @import("forbear");
const Button = @import("button.zig").Button;
const Section = @import("section.zig").Section;

pub fn Header() !void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        forbear.element(.{
            .style = .{
                .minHeight = 72.0,
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .padding = .inLine(15.0),
                .yJustification = .center,
            },
        })({
            forbear.Image(.{
                .width = .{ .fixed = 100.0 },
                .margin = forbear.Margin.right(24.0),
            }, try forbear.useImage("uhoh-logo"));
            forbear.element(.{
                .style = .{
                    .width = .{ .grow = 1.0 },
                    .background = .{ .color = .{ 1.0, 0.0, 0.0, 1.0 } },
                },
            })({});
            forbear.element(.{
                .style = .{
                    .fontWeight = 500,
                    .margin = .right(16.0),
                    .padding = .all(20.0),
                },
            })({
                if (forbear.on(.mouseOver)) {
                    forbear.setCursor(.pointer);
                }
                forbear.text("Pricing");
            });
            Button(.{})({
                forbear.text("Try it risk-free");
            });
        });
    });
}
