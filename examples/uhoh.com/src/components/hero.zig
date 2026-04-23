const forbear = @import("forbear");
const Button = @import("button.zig").Button;
const Section = @import("section.zig").Section;

pub fn Hero() !void {
    Section(.{
        .margin = .block(36.0),
        .direction = .horizontal,
        .xJustification = .start,
        .yJustification = .center,
    })({
        forbear.element(.{
            .direction = .vertical,
            .width = .{ .grow = 2.0 },
            .padding = .right(30.0),
        })({
            forbear.element(.{
                .fontWeight = 700,
                .fontSize = 64,
                .lineHeight = 0.9,
                .margin = .bottom(24.0),
            })({
                forbear.text("You're the boss, why are you still fixing tech issues?");
            });
            forbear.element(.{
                .fontSize = 20.0,
                .margin = .bottom(25.0),
                .lineHeight = 1.2,
            })({
                forbear.text("It doesn't just annoy you. It slows you and your staff down. That's our job now.");
            });
            Button(.{})({
                forbear.text("Let us prove it*");
            });
            forbear.element(.{
                .fontSize = 12.0,
                .lineHeight = 1.3,
                .maxWidth = 420.0,
                .margin = .top(20.0),
            })({
                forbear.text(
                    "* You have to promise us that you'll dump all your problems on us so that we can show you what we're made of.",
                );
            });
        });
        forbear.image(.{
            .width = .{ .grow = 1.0 },
            .blendMode = .darken,
        }, try forbear.useImage("uhoh-hero"));
    });
}
