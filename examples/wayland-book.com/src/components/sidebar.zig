const forbear = @import("forbear");
const Colors = @import("../colors.zig");

pub fn Sidebar() *const fn (void) void {
    forbear.component("sidebar")({
        forbear.element(.{
            .width = .{ .fixed = 280.0 },
            .height = .grow,
            .background = .{ .color = Colors.sidebar },
            .direction = .vertical,
            .xJustification = .start,
            .yJustification = .start,
            .padding = forbear.Padding.block(18.0),
            .color = Colors.sidebarText,
        })({
            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}

pub fn SidebarDivider() void {
    forbear.element(.{
        .width = .grow,
        .borderWidth = forbear.BorderWidth.top(0.75),
        .borderColor = Colors.sidebarBorder,
        .margin = forbear.Margin.bottom(6.0),
    })({});
}

pub const SidebarItemProps = struct {
    active: bool = false,
    depth: f32 = 0,
};

pub fn SidebarItem(props: SidebarItemProps) *const fn (void) void {
    forbear.component("sidebar-item")({
        const isHovering = forbear.useState(bool, false);

        forbear.element(.{
            .width = .grow,
            .direction = .horizontal,
            .xJustification = .start,
            .yJustification = .center,
            .padding = forbear.Padding.block(6.0).withInLine(12.0 + props.depth * 16.0),
            .cursor = .pointer,
            .color = if (props.active) Colors.sidebarActive else null,
            .background = .{
                .color = if (isHovering.* or props.active)
                    .{ 0.15, 0.17, 0.19, 1.0 }
                else
                    .{ 0.0, 0.0, 0.0, 0.0 },
            },
            .fontSize = 10.5,
            .fontWeight = if (props.active) 600 else 400,
        })({
            if (forbear.on(.mouseOver)) isHovering.* = true;
            if (forbear.on(.mouseOut)) isHovering.* = false;

            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}

