const std = @import("std");
const gpu = std.gpu;

extern var vertexColor: @Vector(4, f32) addrspace(.output);

export fn main() callconv(.spirv_vertex) void {
    gpu.location(&vertexColor, 0);

    if (gpu.vertex_index == 0) {
        gpu.position_out.* = .{
            0.0, -0.5, 0.0, 1.0,
        };
        vertexColor = .{ 1.0, 0.0, 0.0, 1.0 };
    } else if (gpu.vertex_index == 1) {
        gpu.position_out.* = .{
            0.5, 0.5, 0.0, 1.0,
        };
        vertexColor = .{ 0.0, 1.0, 0.0, 1.0 };
    } else if (gpu.vertex_index == 2) {
        gpu.position_out.* = .{
            -0.5, 0.5, 0.0, 1.0,
        };
        vertexColor = .{ 0.0, 0.0, 1.0, 1.0 };
    }
}
