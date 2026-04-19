const forbear = @import("forbear");
const theme = @import("theme.zig");

pub const ButtonProps = struct {
    sizing: enum { medium, large } = .medium,
};

pub fn Button(props: ButtonProps) *const fn (void) void {
    forbear.component("button")({
        const isHovering = forbear.useState(bool, false);

        forbear.element(.{})({
            if (forbear.on(.mouseOver)) {
                isHovering.* = true;
            }
            if (forbear.on(.mouseOut)) {
                isHovering.* = false;
            }

            forbear.element(.{
                .borderRadius = 6.0,
                .borderWidth = forbear.BorderWidth.all(1.5),
                .background = .{ .color = .{ 1.0, 1.0, 1.0, 1.0 } },
                .borderColor = .{ 0.0, 0.0, 0.0, 1.0 },
                .cursor = .pointer,
                .textWrapping = .none,
                .fontSize = switch (props.sizing) {
                    .medium => 12,
                    .large => 20,
                },
                .translate = .{
                    0.0,
                    forbear.useTransition(if (isHovering.*) -4.5 else 0.0, 0.1, forbear.easeInOut),
                },
                .shadow = .{
                    .blurRadius = 0.0,
                    .spread = 0.0,
                    .color = .{ 0.0, 0.0, 0.0, 1.0 },
                    .offset = forbear.Offset.bottom(
                        forbear.useTransition(if (isHovering.*) 4.5 else 0.0, 0.1, forbear.easeInOut),
                    ),
                },
                .padding = switch (props.sizing) {
                    .medium => forbear.Padding.block(10).withInLine(20),
                    .large => forbear.Padding.block(28).withInLine(48),
                },
                .xJustification = .center,
                .yJustification = .center,
                .direction = .vertical,
            })({
                forbear.componentChildrenSlot();
            });
        });
    });
    return forbear.componentChildrenSlotEnd();
}
