const gl = @import("zopengl").bindings;

pub const c = @import("c.zig").c;
pub const Window = @import("window.zig");

pub fn render(window: *Window) !void {
    _ = window;
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
}
