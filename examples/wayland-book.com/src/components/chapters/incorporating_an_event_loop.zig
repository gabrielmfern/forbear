const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn IncorporatingAnEventLoop() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Incorporating an event loop");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
