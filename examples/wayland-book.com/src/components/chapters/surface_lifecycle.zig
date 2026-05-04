const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SurfaceLifecycle() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Surface lifecycle");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
