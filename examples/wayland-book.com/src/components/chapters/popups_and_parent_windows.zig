const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn PopupsAndParentWindows() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Popus & parent windows");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
