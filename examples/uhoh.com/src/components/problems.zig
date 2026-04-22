const forbear = @import("forbear");
const colors = @import("../colors.zig");
const Button = @import("button.zig").Button;
const Section = @import("section.zig").Section;

const Vec4 = @Vector(4, f32);

fn Problem(style: forbear.Style, text: []const u8) !void {
    forbear.element(style.overwrite(.{
        .padding = .block(12.0),
        .fontSize = 14.0,
        .borderColor = colors.black,
    }))({
        forbear.image(.{
            .width = .{ .fixed = 30.0 },
            .height = .{ .fixed = 30.0 },
            .blendMode = .multiply,
            .margin = .right(20.0),
        }, try forbear.useImage("uhoh-x-red"));
        forbear.text(text);
    });
}

pub fn Problems() !void {
    Section(.{
        .padding = forbear.Padding.block(48.0).withInLine(15.0),
    })({
        forbear.image(.{
            .width = .{ .grow = 0.75 },
            .maxWidth = 369,
            .blendMode = .multiply,
        }, try forbear.useImage("uhoh-problem"));
        forbear.element(.{
            .direction = .vertical,
            .width = .{ .grow = 1.0 },
            .padding = .left(60.0),
        })({
            forbear.element(.{
                .fontSize = 24.0,
            })({
                forbear.text("You're a growing business.");
            });
            forbear.element(.{
                .fontWeight = 700,
                .fontSize = 40.0,
                .margin = forbear.Margin.top(20.0).withBottom(25.0),
            })({
                forbear.text("But your day-to-day has some of this BS in it:");
            });

            try Problem(.{}, "You got a cryptic error message on an app. Now you have to submit a ticket.");
            try Problem(.{ .borderWidth = .top(2.0) }, "Your Google ads literally just got disabled and you're not sure why. Now you have to submit a ticket.");
            try Problem(.{ .borderWidth = .top(2.0) }, "Someone on your team lost access to a shared account. Now you have to submit a ticket.");

            forbear.element(.{
                .margin = .bottom(40.0),
            })({
                forbear.text("Imagine if you could delegate all these issues to a genie?");
            });
            Button(.{})({
                forbear.text("Get a free trial");
            });
        });
    });
}
