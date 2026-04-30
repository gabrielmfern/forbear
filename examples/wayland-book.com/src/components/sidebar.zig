const std = @import("std");
const forbear = @import("forbear");
const Colors = @import("../colors.zig");

pub fn Sidebar() *const fn (void) void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        forbear.element(.{
            .style = .{
                .width = .{ .fixed = 300.0 },
                .height = .{ .grow = 1.0 },
                .direction = .vertical,
                .xJustification = .start,
                .yJustification = .start,
                .background = .{ .color = Colors.sidebarBackground },
                .padding = forbear.Padding.all(10.0),
                .fontSize = 14.0,
                .color = Colors.sidebarText,
            },
        })({
            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}

pub fn SidebarDivider() void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .borderWidth = forbear.BorderWidth.top(0.75),
                .borderColor = Colors.border,
                .margin = forbear.Margin.bottom(6.0),
            },
        })({});
    });
}

pub const SidebarItemProps = struct {
    active: bool = false,
    depth: f32 = 0,
    key: ?[]const u8 = null,
};

pub fn SidebarItem(props: SidebarItemProps) *const fn (void) void {
    forbear.component(
        if (props.key) |key|
            .{ .text = key }
        else
            .{ .sourceLocation = @src() },
    )({
        const isHovering = forbear.useState(bool, false);

        forbear.element(.{
            .style = .{
                .width = .{ .grow = 1.0 },
                .direction = .horizontal,
                .textWrapping = .none,
                .xJustification = .start,
                .yJustification = .center,
                .padding = forbear.Padding.left(props.depth * 20.0),
                .lineHeight = if (props.depth > 0) 1.9 else 2.2,
                .cursor = .pointer,
                .color = if (props.active or isHovering.*) Colors.sidebarActive else null,
                .fontWeight = if (props.active) 600 else 400,
            },
        })({
            forbear.componentChildrenSlot();

            if (forbear.on(.mouseOver)) isHovering.* = true;
            if (forbear.on(.mouseOut)) isHovering.* = false;
        });
    });
    return forbear.componentChildrenSlotEnd();
}
