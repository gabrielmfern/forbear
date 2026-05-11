const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn Acknowledgements() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Acknowledgements");
        });

        Paragraph(.{})({
            forbear.text("TODO");
        });
    });
}
