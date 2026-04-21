const forbear = @import("forbear");
const Colors = @import("../colors.zig");
const Button = @import("button.zig").Button;

const Vec4 = @Vector(4, f32);
const black: Vec4 = .{ 0.01, 0.019, 0.07, 1.0 };

const issues = [_][]const u8{
    "You got a cryptic error message on an app. Now you have to submit a ticket.",
    "Your Google ads literally just got disabled and you're not sure why. Now you have to submit a ticket.",
    "Someone on your team lost access to a shared account. Now you have to submit a ticket.",
};

pub fn Problems() !void {
    forbear.element(.{
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .xJustification = .center,
        .yJustification = .start,
        .padding = forbear.Padding.top(22.5).withBottom(30.0),
    })({
        forbear.image(.{
            .width = .{ .grow = 1.0 },
            .maxWidth = 369,
            .blendMode = .multiply,
            .margin = forbear.Margin.inLine(0.0).withRight(24.0),
        }, try forbear.useImage("uhoh-problem"));
        forbear.element(.{
            .direction = .vertical,
            .width = .{ .grow = 1.0 },
        })({
            forbear.element(.{
                .fontWeight = 600,
                .fontSize = 10.5,
                .color = Colors.muted,
            })({
                forbear.text("You're a growing business.");
            });
            forbear.element(.{
                .fontWeight = 700,
                .fontSize = 24.0,
                .margin = forbear.Margin.block(4.5).withBottom(12.0),
            })({
                forbear.text("But your day-to-day has some of this BS in it:");
            });

            for (issues, 0..) |issue, i| {
                forbear.element(.{
                    .direction = .horizontal,
                    .padding = .block(9.0),
                    .fontSize = 10.5,
                    .borderWidth = if (i == 0) null else .top(1.5),
                    .borderColor = black,
                })({
                    forbear.image(.{
                        .width = .{ .fixed = 30.0 },
                        .height = .{ .fixed = 30.0 },
                        .blendMode = .multiply,
                        .margin = .right(7.5),
                    }, try forbear.useImage("uhoh-x-red"));
                    forbear.element(.{ .fontSize = 12.0 })({
                        forbear.text(issue);
                    });
                });
            }
            forbear.element(.{
                .fontSize = 12.0,
                .margin = .bottom(30.0),
            })({
                forbear.text("Imagine if you could delegate all these issues to a genie?");
            });
            Button(.{})({
                forbear.text("Get a free trial");
            });
        });
    });
}
