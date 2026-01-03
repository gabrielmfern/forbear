#version 450

layout(location = 0) in vec3 vertexPosition;
layout(location = 0) out vec2 outUV;
layout(location = 1) out vec4 outColor;

struct GlyphRenderingData {
    mat4 modelViewProjectionMatrix;
    vec4 color;
    vec2 uvOffset;
    vec2 uvSize;
};

layout(std430, set = 0, binding = 0) readonly buffer RenderingData {
    GlyphRenderingData data[];
} renderingData;

void main() {
    GlyphRenderingData d = renderingData.data[gl_InstanceIndex];
    gl_Position = d.modelViewProjectionMatrix * vec4(vertexPosition, 1.0);
    outColor = d.color;
    outUV = d.uvOffset + vertexPosition.xy * d.uvSize;
}
