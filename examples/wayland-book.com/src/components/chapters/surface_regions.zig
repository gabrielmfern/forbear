const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SurfaceRegions() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Surface regions");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
