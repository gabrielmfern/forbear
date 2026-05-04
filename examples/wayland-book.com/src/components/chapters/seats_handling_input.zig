const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SeatsHandlingInput() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Seats: Handling input");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
