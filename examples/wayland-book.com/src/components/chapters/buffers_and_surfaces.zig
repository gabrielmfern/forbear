const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn BuffersAndSurfaces() void {
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
                forbear.text("Buffers & surfaces");
            });

            Paragraph()({
                forbear.text("Apparently, the whole point of this system is to display information to users and receive their feedback for additional processing. In this chapter, we'll explore the first of these tasks: showing pixels on the screen.");
            });

            Paragraph()({
                forbear.text("There are two primitives which are used for this purpose: buffers and surfaces, governed respectively by the wl_buffer and wl_surface interfaces. Buffers act as an opaque container for some underlying pixel storage, and are supplied by clients with a number of methods \u{2014} shared memory buffers and GPU handles being the most common.");
            });
        });
    });
}
