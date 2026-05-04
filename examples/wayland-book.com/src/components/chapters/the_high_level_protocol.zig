const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn TheHighLevelProtocol() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("The high-level protocol");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
