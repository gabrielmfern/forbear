const forbear = @import("forbear");
const theme = @import("theme.zig");

pub const ButtonProps = struct {
    sizing: enum { medium, large } = .medium,
};

pub fn Button(props: ButtonProps) !*const fn (void) void {
    forbear.component("button")({
        const isHovering = try forbear.useState(bool, false);

        forbear.element(.{})({
            forbear.element(.{
                .borderRadius = 6.0,
                .borderWidth = forbear.BorderWidth.all(1.5),
                .background = .{ .color = .{ 1.0, 1.0, 1.0, 1.0 } },
                .borderColor = .{ 0.0, 0.0, 0.0, 1.0 },
                .cursor = .pointer,
                .fontSize = switch (props.sizing) {
                    .medium => 12,
                    .large => 20,
                },
                .translate = .{
                    0.0,
                    try forbear.useTransition(if (isHovering.*) -4.5 else 0.0, 0.1, forbear.easeInOut),
                },
                .shadow = .{
                    .blurRadius = 0.0,
                    .spread = 0.0,
                    .color = .{ 0.0, 0.0, 0.0, 1.0 },
                    .offset = forbear.Offset.bottom(
                        try forbear.useTransition(if (isHovering.*) 4.5 else 0.0, 0.1, forbear.easeInOut),
                    ),
                },
                .padding = switch (props.sizing) {
                    .medium => forbear.Padding.block(10).withInLine(20),
                    .large => forbear.Padding.block(28).withInLine(48),
                },
                .alignment = .center,
                .direction = .topToBottom,
            })({
                forbear.componentChildrenSlot();
            });
        });

        while (forbear.useNextEvent()) |event| {
            switch (event) {
                .mouseOver => {
                    isHovering.* = true;
                },
                .mouseOut => {
                    isHovering.* = false;
                },
            }
        }
    });
    return forbear.componentChildrenEnd();
}
