const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn Positioners() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Positioners");
        });

        Paragraph(.{})({
            forbear.text("TODO");
        });
    });
}
