const root = @import("root.zig");

const Vec4 = @Vector(4, f32);
const Vec3 = @Vector(3, f32);

pub const LayoutBox = struct {
    position: Vec3,
    scale: Vec3,
    backgroundColor: Vec4,
    borderRadius: f32,
};
