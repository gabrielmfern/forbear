const forbear = @import("forbear");

const Vec4 = @Vector(4, f32);
const black: Vec4 = .{ 0.01, 0.019, 0.07, 1.0 };

const statements = [_][]const u8{
    "Less problems, more productivity",
    "Your team runs smoother",
    "A hundred things less on your plate",
};

pub fn Statements() !void {
    forbear.element(.{
        .width = .{ .grow = 1.0 },
        .maxWidth = 940.0,
        .xJustification = .center,
        .yJustification = .start,
        .padding = .block(30.0),
        .margin = .block(48.0),
        .borderWidth = .block(2.0),
        .borderColor = black,
    })({
        for (statements, 0..) |statement, i| {
            forbear.element(.{
                .direction = .horizontal,
                .xJustification = .start,
                .yJustification = .center,
                .width = .{ .grow = 1.0 },
                .padding = if (i > 0) .left(20.0) else null,
            })({
                forbear.image(.{
                    .width = .{ .fixed = 30.0 },
                    .height = .{ .fixed = 30.0 },
                    .blendMode = .multiply,
                    .margin = .right(15.0),
                }, try forbear.useImage("uhoh-check"));
                forbear.text(statement);
            });
        }
    });
}
