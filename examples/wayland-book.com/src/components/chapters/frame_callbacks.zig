const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn FrameCallbacks() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Frame callbacks");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
