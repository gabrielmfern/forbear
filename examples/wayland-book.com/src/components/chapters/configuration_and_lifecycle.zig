const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ConfigurationAndLifecycle() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Configuration & lifecycle");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
