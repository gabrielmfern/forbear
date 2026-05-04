const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn WaylandUtilPrimitives() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("wayland-util primitives");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
