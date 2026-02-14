#version 450

layout(location = 0) in vec3 vertexPosition;

layout(location = 0) out vec4 vertexColor;
layout(location = 1) out float borderRadius;
layout(location = 2) out vec4 localPos;
layout(location = 3) out vec2 size;
layout(location = 4) out vec2 elementSize;
layout(location = 5) out float blur;
layout(location = 6) out float spread;
layout(location = 7) out vec2 elementOffset;

struct ShadowRenderingData {
    float blur;
    float borderRadius;
    vec4 color;
    mat4 modelViewProjectionMatrix;
    vec2 elementSize;
    vec2 elementOffset;
    vec2 size;
    float spread;
};

layout(std430, set = 0, binding = 0) readonly buffer RenderingData {
    ShadowRenderingData data[];
} renderingData;

void main() {
    ShadowRenderingData data = renderingData.data[gl_InstanceIndex];

    gl_Position = data.modelViewProjectionMatrix * vec4(vertexPosition, 1.0);
    vertexColor = data.color;
    borderRadius = data.borderRadius;
    size = data.size;
    elementSize = data.elementSize;
    localPos = vec4(vertexPosition, 1.0);
    blur = data.blur;
    spread = data.spread;
    elementOffset = data.elementOffset;
}
