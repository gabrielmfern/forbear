const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn GlobalsAndTheRegistry() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Globals & the registry");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
