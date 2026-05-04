const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn HighDensitySurfaces() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("High density surfaces (HiDPI)");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
