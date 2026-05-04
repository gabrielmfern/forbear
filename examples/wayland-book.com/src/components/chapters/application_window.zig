const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ApplicationWindow() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Application window");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
