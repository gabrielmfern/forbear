const forbear = @import("forbear");
const Colors = @import("../colors.zig");

pub fn Heading(level: u8) *const fn (void) void {
    forbear.component("heading")({
        const size: f32 = switch (level) {
            1 => 32.0,
            2 => 22.0,
            else => 17.0,
        };
        const topMargin: f32 = switch (level) {
            1 => 0.0,
            2 => 24.0,
            else => 18.0,
        };
        forbear.element(.{
            .width = .grow,
            .fontWeight = 700,
            .fontSize = size,
            .color = Colors.heading,
            .margin = forbear.Margin.top(topMargin).withBottom(13.5),
            .lineHeight = 1.2,
        })({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}
