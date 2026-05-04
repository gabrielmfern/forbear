const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn InterfacesRequestsEvents() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Interfaces, requests, events");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
