const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn WhatsInThePackage() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("What's in the package");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
