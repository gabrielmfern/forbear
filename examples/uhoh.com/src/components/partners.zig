const forbear = @import("forbear");
const colors = @import("../colors.zig");

const Vec4 = @Vector(4, f32);

pub fn Partners() !void {
    forbear.element(.{
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .padding = .all(20.0),
        .margin = .block(96.0),
        .borderWidth = .all(2.0),
        .borderColor = colors.black,
        .borderRadius = 9.0,
        .direction = .vertical,
    })({
        forbear.element(.{
            .fontWeight = 700,
            .width = .{ .grow = 1.0 },
            .xJustification = .center,
            .yJustification = .center,
            .fontSize = 24.0,
            .margin = forbear.Margin.top(20.0).withBottom(42.0),
        })({
            forbear.text("Our partners");
        });
        forbear.element(.{
            .direction = .horizontal,
            .width = .{ .grow = 1.0 },
            .margin = .block(8.0),
            .xJustification = .center,
            .yJustification = .center,
        })({
            const logos = [_][]const u8{
                "uhoh-partner-badge",
                "uhoh-google-logo",
                "uhoh-microsoft-logo",
                "uhoh-partner-logo",
                "uhoh-zoho-logo",
            };

            for (logos, 0..) |image, i| {
                forbear.image(.{
                    .maxWidth = 128,
                    .maxHeight = 112,
                    .width = .{ .grow = 1.0 },
                    .filter = .grayscale,
                    .margin = if (i > 0) .left(48.0) else null,
                }, try forbear.useImage(image));
            }
        });
    });
}
