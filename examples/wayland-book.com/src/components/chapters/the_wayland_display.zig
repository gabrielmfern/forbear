const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn TheWaylandDisplay() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("The Wayland display");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
