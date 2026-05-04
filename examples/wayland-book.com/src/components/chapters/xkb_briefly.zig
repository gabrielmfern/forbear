const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn XkbBriefly() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("XKB, briefly");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
