const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn CreatingADisplay() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Creating a display");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
