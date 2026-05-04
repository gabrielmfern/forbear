const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn InterfacesAndListeners() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Interfaces & listeners");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
