const forbear = @import("forbear");

pub fn Section(style: forbear.Style) *const fn (void) void {
    forbear.component("Section")({
        forbear.element(.{
            .width = .{ .grow = 1.0 },
            .xJustification = .center,
            .padding = forbear.Padding.block(48.0).withInLine(15.0),
        })({
            forbear.element(style.overwrite(.{
                .width = .{ .grow = 1.0 },
                .maxWidth = 940.0,
                .xJustification = .center,
            }))({
                forbear.componentChildrenSlot();
            });
        });
    });
    return forbear.componentChildrenSlotEnd();
}
