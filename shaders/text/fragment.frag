#version 450

layout(location = 0) in vec2 inUV;
layout(location = 1) in vec4 inColor;

layout(location = 0) out vec4 fragColor;

layout(set = 0, binding = 1) uniform sampler2D fontAtlas;

layout(push_constant) uniform TextPushConstants {
    float gamma;
} pc;

void main() {
    vec3 coverage = texture(fontAtlas, inUV).rgb;

    coverage = pow(coverage, vec3(pc.gamma));

    fragColor = vec4(inColor.rgb * coverage, inColor.a * dot(coverage, vec3(1.0 / 3.0)));
}
