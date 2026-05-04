const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn WireProtocolBasics() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Wire protocol basics");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
