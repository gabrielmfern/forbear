const std = @import("std");
const gpu = std.gpu;

extern const vertexPosition: @Vector(3, f32) addrspace(.input);
extern const vertexColor: @Vector(3, f32) addrspace(.input);

extern var vertexColorForFrag: @Vector(4, f32) addrspace(.output);

export fn main() callconv(.spirv_vertex) void {
    gpu.location(&vertexPosition, 0);
    gpu.location(&vertexColor, 1);
    gpu.location(&vertexColorForFrag, 0);

    gpu.position_out.* = .{ vertexPosition[0], vertexPosition[1], vertexPosition[2], 1.0 };
    vertexColorForFrag = .{ vertexColor[0], vertexColor[1], vertexColor[2], 1.0 };
}
