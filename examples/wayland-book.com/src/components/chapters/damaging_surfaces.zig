const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn DamagingSurfaces() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Damaging surfaces");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
