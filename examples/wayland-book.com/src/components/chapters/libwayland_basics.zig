const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn LibwaylandBasics() void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .direction = .vertical,
                .xJustification = .center,
                .yJustification = .start,
                .padding = forbear.Padding.all(15.0),
                .maxWidth = 750.0,
            },
        })({
            Heading(.{ .level = 1 })({
                forbear.text("Libwayland basics");
            });

            Heading(.{ .level = 2 })({
                forbear.text("The libwayland implementation");
            });

            Paragraph(.{})({
                forbear.text("We spoke briefly about libwayland in chapter 1.3 \u{2014} the most popular Wayland implementation. Much of this book is applicable to any implementation, but we're going to spend the next two chapters familiarizing you with this one.");
            });

            Paragraph(.{})({
                forbear.text("The Wayland package includes pkg-config specs for wayland-client and wayland-server \u{2014} consult your build system's documentation for instructions on linking with them. Naturally, most applications will only link to one or the other. The library includes a few simple primitives (such as a linked list) and a pre-compiled version of wayland.xml \u{2014} the core Wayland protocol.");
            });

            Paragraph(.{})({
                forbear.text("We'll start by introducing the primitives.");
            });
        });
    });
}
