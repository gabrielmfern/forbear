const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn AccurateTiming() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Accurate timing");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
