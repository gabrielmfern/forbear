const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ProtocolDesignPatterns() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Protocol design patterns");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
