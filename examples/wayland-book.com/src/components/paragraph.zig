const forbear = @import("forbear");
const Colors = @import("../colors.zig");

pub const ParagraphProps = struct {
    style: forbear.Style = .{},
};

pub fn Paragraph(props: ParagraphProps) *const fn (void) void {
    forbear.component(.{
        .sourceLocation = @src(),
    })({
        forbear.element(.{
            .style = props.style.overwrite(.{
                .width = .{ .grow = 1.0 },
                .fontSize = 16.0,
                .margin = .bottom(16.0),
            }),
        })({
            forbear.componentChildrenSlot();
        });
    });
    return forbear.componentChildrenSlotEnd();
}
