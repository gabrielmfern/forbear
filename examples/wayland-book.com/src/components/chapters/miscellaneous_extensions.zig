const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn MiscellaneousExtensions() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Miscellaneous extensions");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
