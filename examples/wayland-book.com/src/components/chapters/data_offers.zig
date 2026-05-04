const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn DataOffers() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Data offers");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
