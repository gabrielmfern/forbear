#version 450

layout(location = 0) in vec2 inUV;
layout(location = 1) in vec4 inColor;

// Dual-source blending outputs for subpixel text rendering
// index 0: pre-multiplied text color (color * coverage per channel)
// index 1: blend weights for per-channel blending
layout(location = 0, index = 0) out vec4 fragColor;
layout(location = 0, index = 1) out vec4 blendWeights;

layout(set = 0, binding = 1) uniform sampler2D fontAtlas;

void main() {
    vec3 coverage = texture(fontAtlas, inUV).rgb;
    
    fragColor = vec4(inColor.rgb * coverage, 1.0);
    blendWeights = vec4(coverage * inColor.a, inColor.a);
}
