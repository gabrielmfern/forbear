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

// Frame-constant orthographic projection, set once per draw via push constant
// instead of baking a full mat4 into every glyph on the CPU.
layout(push_constant) uniform PushConstants {
    mat4 projection;
} pushConstants;

void main() {
    GlyphRenderingData d = renderingData.data[gl_InstanceIndex];
    // The unit quad (vertexPosition.xy in [0,1]) is scaled by the glyph size and
    // offset to its pixel position, then projected. This replaces the per-glyph
    // scaling*translation*projection matrix multiply that used to run on the CPU.
    vec2 screenPosition = d.position + vertexPosition.xy * d.size;
    gl_Position = pushConstants.projection * vec4(screenPosition, 0.0, 1.0);
    outColor = d.color;
    outUV = d.uvOffset + vertexPosition.xy * d.uvSize;
}
