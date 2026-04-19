const forbear = @import("forbear");
const Colors = @import("../colors.zig");

pub fn Paragraph() *const fn (void) void {
    forbear.component("paragraph")({
        forbear.element(.{
            .width = .grow,
            .fontSize = 12.0,
            .lineHeight = 1.6,
            .margin = .bottom(13.5),
        })({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}
