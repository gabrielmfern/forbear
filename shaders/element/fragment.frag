#version 450

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in float borderRadius;
layout(location = 2) in vec4 localPos;
layout(location = 3) in vec2 size;
layout(location = 0) out vec4 outColor;

void main() {
    vec2 p = (localPos.xy - 0.5) * size;

    float r = min(borderRadius, min(size.x, size.y) * 0.5);

    if (abs(p.x) >= size.x * 0.5 - r && abs(p.y) >= size.y * 0.5 - r) {
        vec2 q = abs(p) - size * 0.5 + r;
        if (length(q) > r) {
            discard;
        }
    }

    outColor = vertexColor;
}
