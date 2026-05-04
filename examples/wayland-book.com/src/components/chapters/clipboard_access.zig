const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ClipboardAccess() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Clipboard access");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
