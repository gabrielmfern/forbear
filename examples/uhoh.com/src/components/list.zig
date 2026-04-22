const forbear = @import("forbear");

pub fn List() *const fn (void) void {
    forbear.component("list")({
        forbear.element(.{
            .direction = .vertical,
            .padding = .left(40.0),
            .margin = .block(16.0),
        })({
            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}

pub fn ListItem() *const fn (void) void {
    forbear.component("list-item")({
        forbear.element(.{
            .direction = .horizontal,
            .margin = .bottom(5.0),
        })({
            forbear.text("• ");

            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}
