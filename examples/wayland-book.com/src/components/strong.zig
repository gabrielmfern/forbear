const forbear = @import("forbear");

pub fn Strong() *const fn (void) void {
    forbear.component("strong")({
        forbear.element(.{
            .fontWeight = 700,
        })({
            forbear.componentChildrenSlot();
        });
    });
    
    return forbear.componentChildrenSlotEnd();
}
