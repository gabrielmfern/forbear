#version 450

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in float borderRadius;
layout(location = 2) in vec4 localPos;
layout(location = 3) in vec2 size;
layout(location = 0) out vec4 outColor;

float sdRoundedBox(in vec2 p, in vec2 b, in float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 p = localPos.xy * size;

    // Clamp radius to half-size to ensure perfect circles
    float r = min(borderRadius, min(size.x, size.y) * 0.5);
    float d = sdRoundedBox(p, size * 0.5, r);

    // Antialias centered on d=0
    float fw = fwidth(d);
    float alpha = 1.0 - smoothstep(-fw * 0.5, fw * 0.5, d);

    if (alpha <= 0.0) discard;

    outColor = vec4(vertexColor.rgb, vertexColor.a * alpha);
}
