const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SurfaceBasics() void {
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
                forbear.text("Surface basics");
            });

            Paragraph()({
                forbear.text("The point of a windowing system is to put information in front of users and to take their input back for further processing. This chapter focuses on the first half of that exchange: getting pixels onto the screen.");
            });

            Paragraph()({
                forbear.text("Wayland uses two primitives to accomplish this, governed by the wl_buffer and wl_surface interfaces. A buffer is an opaque handle to some underlying pixel storage that the client provides; shared memory buffers and GPU handles are the two most common kinds.");
            });
        });
    });
}
