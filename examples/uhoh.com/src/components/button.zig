const forbear = @import("forbear");
const colors = @import("../colors.zig");

pub const ButtonProps = struct {
    style: forbear.Style = .{},
    sizing: enum { medium, large } = .medium,
};

pub fn Button(props: ButtonProps) *const fn (void) void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        const isHovering = forbear.useState(bool, false);

        forbear.element(.{})({
            if (forbear.on(.mouseOver)) {
                isHovering.* = true;
                forbear.setCursor(.pointer);
            }
            if (forbear.on(.mouseOut)) {
                isHovering.* = false;
            }

            forbear.element(.{ .style = props.style.overwrite(.{
                .borderRadius = 8.0,
                .borderWidth = .all(2.0),
                .background = .{ .color = forbear.white },
                .borderColor = colors.black,
                .textWrapping = .none,
                .fontSize = switch (props.sizing) {
                    .medium => 16.0,
                    .large => 24.0,
                },
                .translate = .{
                    0.0,
                    forbear.useTransition(if (isHovering.*) -6.0 else 0.0, 0.1, forbear.easeInOut),
                },
                .shadow = .{
                    .blurRadius = 0.0,
                    .spread = 0.0,
                    .color = .{ 0.0, 0.0, 0.0, 1.0 },
                    .offset = forbear.Offset.bottom(
                        forbear.useTransition(if (isHovering.*) 6.0 else 0.0, 0.1, forbear.easeInOut),
                    ),
                },
                .padding = switch (props.sizing) {
                    .medium => forbear.Padding.block(13).withInLine(25),
                    .large => forbear.Padding.block(25).withInLine(50),
                },
                .xJustification = .center,
                .yJustification = .center,
                .direction = .vertical,
            }) })({
                forbear.componentChildrenSlot();
            });
        });
    });
    return forbear.componentChildrenSlotEnd();
}
