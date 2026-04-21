const forbear = @import("forbear");
const Colors = @import("../colors.zig");

pub fn Paragraph() *const fn (void) void {
    forbear.component("paragraph")({
        forbear.element(.{
            .width = .{ .grow = 1.0 },
            .fontSize = 16.0,
            .lineHeight = 1.5,
            .margin = .bottom(16.0),
        })({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}
