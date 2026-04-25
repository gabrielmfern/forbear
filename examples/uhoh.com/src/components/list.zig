const forbear = @import("forbear");

pub fn List() *const fn (void) void {
    forbear.component(@src())({
        forbear.element(.{ .style = .{
            .width = .{ .grow = 1.0 },
            .direction = .vertical,
            .padding = .left(40.0),
            .margin = .block(16.0),
        } })({
            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}

pub fn ListItem() *const fn (void) void {
    forbear.component(@src())({
        forbear.element(.{ .style = .{
            .width = .{ .grow = 1.0 },
            .direction = .horizontal,
            .margin = .bottom(10.0),
        } })({
            forbear.text("• ");

            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}
