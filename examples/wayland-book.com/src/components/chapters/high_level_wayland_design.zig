const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn HighLevelWaylandDesign() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("High-level Wayland design");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
