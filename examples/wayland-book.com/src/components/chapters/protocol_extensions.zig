const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ProtocolExtensions() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Protocol extensions");
        });

        Paragraph(.{})({
            forbear.text("TODO");
        });
    });
}
