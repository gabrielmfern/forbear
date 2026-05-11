const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ProtocolDesign() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Protocol design");
        });

        Paragraph(.{})({
            forbear.text("TODO");
        });
    });
}
