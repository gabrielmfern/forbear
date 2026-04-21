const forbear = @import("forbear");

const Vec4 = @Vector(4, f32);
const black: Vec4 = .{ 0.01, 0.019, 0.07, 1.0 };

const logos = [_][]const u8{
    "uhoh-partner-badge",
    "uhoh-google-logo",
    "uhoh-microsoft-logo",
    "uhoh-partner-logo",
    "uhoh-zoho-logo",
};

pub fn Partners() !void {
    forbear.element(.{
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .padding = .all(15.0),
        .borderWidth = .all(1.5),
        .borderColor = black,
        .borderRadius = 9.0,
        .direction = .vertical,
    })({
        forbear.element(.{
            .fontWeight = 700,
            .width = .{ .grow = 1.0 },
            .xJustification = .center,
            .yJustification = .center,
            .fontSize = 18.0,
            .margin = forbear.Margin.block(0.0).withBottom(13.5),
        })({
            forbear.text("Our partners");
        });
        forbear.element(.{
            .direction = .horizontal,
            .xJustification = .center,
            .yJustification = .center,
        })({
            for (logos) |id| {
                forbear.image(.{
                    .maxWidth = 128,
                    .maxHeight = 112,
                    .filter = .grayscale,
                    .margin = forbear.Margin.right(13.5),
                }, try forbear.useImage(id));
            }
        });
    });
}
