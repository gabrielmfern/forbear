const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn PointerInput() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Pointer input");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
