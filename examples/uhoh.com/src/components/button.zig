const forbear = @import("forbear");
const theme = @import("theme.zig");

pub const ButtonProps = struct {
    text: []const u8,
    sizing: enum { small, medium, large } = .medium,
};

pub fn Button(props: ButtonProps) !void {
    const arena = try forbear.useArena();
    const isHovering = try forbear.useState(bool, false);

    (try forbear.element(arena, .{}))({
        (try forbear.element(arena, .{
            .borderRadius = 6.0,
            .borderWidth = forbear.BorderWidth.all(1.5),
            .background = .{ .color = .{ 0.99, 0.98, 0.96, 1.0 } },
            .borderColor = .{ 0.0, 0.0, 0.0, 1.0 },
            .fontSize = switch (props.sizing) {
                .small => 12,
                .medium => 16,
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
                .small => forbear.Padding.block(10).withInLine(20),
                .medium => forbear.Padding.block(20).withInLine(36),
                .large => forbear.Padding.block(28).withInLine(48),
            },
            .alignment = .center,
            .direction = .topToBottom,
        }))({
            try forbear.text(arena, props.text);
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
}
