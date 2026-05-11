const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn XdgShellInDepth() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("XDG shell in depth");
        });

        Paragraph(.{})({
            forbear.text("TODO");
        });
    });
}
