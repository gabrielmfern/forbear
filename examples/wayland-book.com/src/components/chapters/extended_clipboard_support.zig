const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ExtendedClipboardSupport() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Extended clipboard support");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
