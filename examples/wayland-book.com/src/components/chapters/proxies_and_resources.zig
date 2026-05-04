const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn ProxiesAndResources() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Proxies & resources");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
