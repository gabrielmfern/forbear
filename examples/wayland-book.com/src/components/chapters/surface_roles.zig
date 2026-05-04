const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SurfaceRoles() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Surface roles");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
