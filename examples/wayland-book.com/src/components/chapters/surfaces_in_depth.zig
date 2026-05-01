const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SurfacesInDepth() void {
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
                forbear.text("Surfaces in depth");
            });

            Paragraph()({
                forbear.text("The basic areas of the surface interface that we've shown until now are sufficient to present data to the user, but the surface interface offers many additional requests and events for more efficient use. Many — if not most — applications do not need to redraw the entire surface each frame. Even deciding when to draw the next frame is best done with the assistance of the compositor. In this chapter, we'll explore the features of wl_surface in depth.");
            });
        });
    });
}
