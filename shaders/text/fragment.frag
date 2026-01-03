#version 450

layout(location = 0) in vec2 inUV;
layout(location = 1) in vec4 inColor;
layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 1) uniform sampler2D fontAtlas;

void main() {
    float alpha = texture(fontAtlas, inUV).r;
    outColor = vec4(inColor.rgb, inColor.a * alpha);
    if (outColor.a == 0.0) discard;
}
