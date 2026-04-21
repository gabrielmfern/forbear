const forbear = @import("forbear");

const rainbowBar = [_]forbear.GradientStop{
    .{ .color = forbear.hex("ff6b9d"), .position = 0.0 },
    .{ .color = forbear.hex("ffb066"), .position = 0.18 },
    .{ .color = forbear.hex("fff066"), .position = 0.36 },
    .{ .color = forbear.hex("9bf088"), .position = 0.54 },
    .{ .color = forbear.hex("6bc7ff"), .position = 0.72 },
    .{ .color = forbear.hex("c69bff"), .position = 1.0 },
};

pub fn RainbowBar() void {
}
