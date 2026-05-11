const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn DragAndDrop() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Drag & drop");
        });

        Paragraph(.{})({
            forbear.text("TODO");
        });
    });
}
