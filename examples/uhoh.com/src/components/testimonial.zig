const forbear = @import("forbear");

const Vec4 = @Vector(4, f32);
const black: Vec4 = .{ 0.01, 0.019, 0.07, 1.0 };

pub fn Testimonial(imageIdentifier: []const u8, style: forbear.Style) *const fn (void) void {
    forbear.component("Testimonial")({
        forbear.element(style.overwrite(.{
            .width = .{ .grow = 1.0 },
            .height = .{ .grow = 1.0 },
            .padding = .all(20.0),
            // .margin = forbear.Margin.bottom(12.0).withInLine(10.0),
            .borderRadius = 12.0,
            .borderColor = black,
            .direction = .vertical,
            .borderWidth = .all(2.0),
        }))({
            forbear.image(
                .{
                    .width = .{ .fixed = 80.0 },
                    .height = .{ .fixed = 80.0 },
                    .borderRadius = 12.0,
                    .margin = .bottom(30.0),
                },
                forbear.useImage(imageIdentifier) catch unreachable,
            );
            forbear.componentChildrenSlot();
        });
    });

    return forbear.componentChildrenSlotEnd();
}
