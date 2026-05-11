const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn PointerConstraints() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Pointer constraints");
        });

        Paragraph(.{})({
            forbear.text("TODO");
        });
    });
}
