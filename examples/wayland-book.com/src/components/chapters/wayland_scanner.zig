const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn WaylandScanner() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("wayland-scanner");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
