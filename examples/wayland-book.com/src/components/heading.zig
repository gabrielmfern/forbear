const forbear = @import("forbear");
const Colors = @import("../colors.zig");

pub const HeadingProps = struct {
    style: forbear.Style = .{},
    level: u8,
};

pub fn Heading(props: HeadingProps) *const fn (void) void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        const size: f32 = switch (props.level) {
            1 => 32.0,
            2 => 24.0,
            else => 19.0,
        };
        const topMargin: f32 = switch (props.level) {
            1 => 0.0,
            2, 3 => 40.0,
            else => 32.0,
        };
        forbear.element(.{
            .style = props.style.overwrite(.{
                .width = .{ .grow = 1.0 },
                .fontWeight = 700,
                .fontSize = size,
                .margin = forbear.Margin.top(topMargin).withBottom(16.0),
            }),
        })({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}
