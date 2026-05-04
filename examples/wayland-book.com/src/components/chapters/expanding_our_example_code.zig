const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ExpandingOurExampleCode() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Expanding our example code");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
