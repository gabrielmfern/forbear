const std = @import("std");
const zmath = @import("zmath");
const gpu = std.gpu;

const Vec3 = @Vector(3, f32);
const Vec4 = @Vector(4, f32);

extern const vertexPosition: Vec3 addrspace(.input);
extern var vertexColorForFrag: Vec4 addrspace(.output);

const UniformBuffer = extern struct {
    modelViewProjectionMatrix: zmath.Mat,
    color: Vec4,
};

extern const ubo: UniformBuffer addrspace(.uniform);

export fn main() callconv(.spirv_vertex) void {
    gpu.location(&vertexPosition, 0);
    gpu.location(&vertexColorForFrag, 0);

    gpu.binding(&ubo, 0, 0);

    gpu.position_out.* = zmath.mul(
        Vec4{ vertexPosition[0], vertexPosition[1], vertexPosition[2], 1.0 },
        ubo.modelViewProjectionMatrix,
    );
    vertexColorForFrag = Vec4{ ubo.color[0], ubo.color[1], ubo.color[2], ubo.color[3] };
}
