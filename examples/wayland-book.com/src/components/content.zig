const std = @import("std");

const forbear = @import("forbear");

const Introduction = @import("./chapters/introduction.zig").Introduction;
const Heading = @import("heading.zig").Heading;

fn Topbar() void {
    forbear.element(.{
        .style = .{
            .width = .{ .grow = 1.0 },
            .direction = .horizontal,
            .yJustification = .center,
            .padding = forbear.Padding.all(15.0),
            .fontSize = 20.0,
            .fontWeight = 200,
        },
    })({
        Heading(.{
            .level = 1,
            .style = .{
                .xJustification = .center,
            },
        })({
            forbear.text("The Wayland Protocol");
        });
        // TODO: add a printer icon SVG
    });
}

pub fn Content(activeChatper: *usize) void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        const viewport = forbear.useViewportSize();
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .height = .{ .fixed = viewport[1] },
                .direction = .vertical,
                .xJustification = .center,
                .yJustification = .start,
            },
        })({
            _ = forbear.useScrolling();

            Topbar();

            switch (activeChatper.*) {
                0 => Introduction(),
                else => {
                    forbear.element(.{
                        .style = .{
                            .width = .{ .grow = 1.0 },
                            .height = .{ .grow = 1.0 },
                            .fontSize = 64.0,
                            .fontWeight = 500,
                            .xJustification = .center,
                            .yJustification = .center,
                        },
                    })({
                        forbear.text("Chapter not implemented yet!");
                    });
                },
            }
        });
    });
}
