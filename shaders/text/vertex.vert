#version 450

layout(location = 0) in vec3 vertexPosition;
layout(location = 0) out vec2 outUV;
layout(location = 1) out vec4 outColor;

struct GlyphRenderingData {
    vec2 position;
    vec2 size;
    vec4 color;
    vec2 uvOffset;
    vec2 uvSize;
};

layout(std430, set = 0, binding = 0) readonly buffer RenderingData {
    GlyphRenderingData data[];
} renderingData;

layout(push_constant) uniform PushConstants {
    mat4 projection;
} pushConstants;

void main() {
    GlyphRenderingData d = renderingData.data[gl_InstanceIndex];
    // vertexPosition.xy is the [0,1] unit quad, reused as UV below.
    vec2 screenPosition = d.position + vertexPosition.xy * d.size;
    gl_Position = pushConstants.projection * vec4(screenPosition, 0.0, 1.0);
    outColor = d.color;
    outUV = d.uvOffset + vertexPosition.xy * d.uvSize;
}
