const std = @import("std");
const gpu = std.gpu;

extern const vertexColor: @Vector(4, f32) addrspace(.input);
extern var outColor: @Vector(4, f32) addrspace(.output);

export fn main() callconv(.spirv_fragment) void {
    // This index specifies what framebuffer it is outputting to
    gpu.location(&outColor, 0);
    gpu.location(&vertexColor, 0);

    outColor = vertexColor;
}
