const forbear = @import("forbear");

const Heading = @import("../heading.zig").Heading;
const Paragraph = @import("../paragraph.zig").Paragraph;

pub fn SharedMemoryBuffers() void {
    forbear.component(.{})({
        Heading(.{ .level = 1 })({
            forbear.text("Shared memory buffers");
        });

        Paragraph(.{})({
            forbear.text("Placeholder content.");
        });
    });
}
