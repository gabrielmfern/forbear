const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SurfacesInDepth() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Surfaces in depth");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
