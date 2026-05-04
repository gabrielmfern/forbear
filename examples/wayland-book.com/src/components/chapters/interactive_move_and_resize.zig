const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn InteractiveMoveAndResize() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Interactive move and resize");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
