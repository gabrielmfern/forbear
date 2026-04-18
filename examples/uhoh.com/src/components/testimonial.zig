const forbear = @import("forbear");

const Vec4 = @Vector(4, f32);
const black: Vec4 = .{ 0.01, 0.019, 0.07, 1.0 };

pub fn Testimonial(uniqueIndentifier: []const u8) *const fn (void) void {
    forbear.component("Testimonial")({
        forbear.element(.{
            .width = .grow,
            .height = .grow,
            .fontSize = 11.25,
            .lineHeight = 1.4,
            .padding = .all(13.5),
            .margin = forbear.Margin.bottom(12.0).withInLine(10.0),
            .borderRadius = 12.0,
            .borderColor = black,
            .direction = .vertical,
            .borderWidth = .all(0.75),
        })({
            forbear.image(
                .{
                    .width = .{ .fixed = 80.0 },
                    .height = .{ .fixed = 80.0 },
                    .borderRadius = 12.0,
                    .margin = .right(10.5),
                },
                forbear.useImage(uniqueIndentifier) catch unreachable,
            );
            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}
