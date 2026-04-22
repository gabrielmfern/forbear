const forbear = @import("forbear");

pub fn Section(style: forbear.Style) *const fn (void) void {
    forbear.component("Section")({
        forbear.element(style.overwrite(.{
            .width = .{ .grow = 1.0 },
            .maxWidth = 940.0,
            .xJustification = .center,
        }))({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}
