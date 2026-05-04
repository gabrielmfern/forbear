const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn LinuxDmabuf() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Linux dmabuf");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
