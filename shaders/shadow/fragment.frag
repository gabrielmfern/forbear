#version 450

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in float borderRadius;
layout(location = 2) in vec4 localPos;
layout(location = 3) in vec2 size;
layout(location = 4) in float blur;
layout(location = 5) in float spread;

layout(location = 0) out vec4 outColor;

void main() {
    vec2 p = (localPos.xy - 0.5) * size;
    float r = min(borderRadius, min(size.x, size.y) * 0.5);

    // SDF for rounded rectangle
    vec2 q = abs(p) - size * 0.5 + r;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;

    vec4 color = vertexColor;
    outColor = color;
    outColor.a *= step(d, 0.0);

    // Gaussian blur
    if (blur > 0.0) {
        float sigma = blur * 0.5;
        float alpha = exp(-0.5 * (d * d) / (sigma * sigma));
        outColor.a *= alpha;
    }

    // Spread effect
    if (spread != 0.0) {
        float spreadDist = spread;
        outColor.a *= smoothstep(-spreadDist, 0.0, -d);
    }
}
