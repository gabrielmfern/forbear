const forbear = @import("forbear");
const Colors = @import("../colors.zig");

pub fn Heading(level: u8) *const fn (void) void {
    forbear.component("heading")({
        const size: f32 = switch (level) {
            1 => 32.0,
            2 => 24.0,
            else => 19.0,
        };
        const topMargin: f32 = switch (level) {
            1 => 0.0,
            2, 3 => 40.0,
            else => 32.0,
        };
        forbear.element(.{
            .fontWeight = 700,
            .fontSize = size,
            .margin = forbear.Margin.top(topMargin).withBottom(16.0),
            .lineHeight = 1.2,
        })({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}
