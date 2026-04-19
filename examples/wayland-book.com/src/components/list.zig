const forbear = @import("forbear");

pub fn List() *const fn (void) void {
    forbear.component("list")({
        forbear.element(.{
            .width = .grow,
            .margin = .block(16.0),
            .direction = .vertical,
            .padding = .left(20.0),
        })({
            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}

pub fn ListItem() *const fn (void) void {
    forbear.component("list")({
        forbear.element(.{
            .width = .grow,
        })({
            forbear.text("• ");

            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}

