#version 450

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in float borderRadius;
layout(location = 2) in vec4 localPos;
layout(location = 3) in vec2 size;
layout(location = 4) in vec2 elementSize;
layout(location = 5) in float blur;
layout(location = 6) in float spread;

layout(location = 0) out vec4 outColor;

void main() {
    // localPos.xy is 0-1 across the quad, convert to pixel coords centered at origin
    vec2 p = (localPos.xy - 0.5) * size;

    // The shadow shape is based on the original element size, not the quad size
    float r = min(borderRadius, min(elementSize.x, elementSize.y) * 0.5);

    // SDF for rounded rectangle (using original element size)
    vec2 q = abs(p) - elementSize * 0.5 + r;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;

    // Apply spread: positive spread expands shadow, negative contracts
    float adjustedDist = d - spread;

    // Calculate alpha based on distance and blur
    float aa = max(fwidth(adjustedDist), 0.0001);
    float alpha;
    if (blur > 0.0) {
        // Smooth falloff from inside to outside over the blur radius
        alpha = 1.0 - smoothstep(-aa, blur + aa, adjustedDist);
    } else {
        // Anti-aliased hard edge when no blur
        alpha = 1.0 - smoothstep(-aa, aa, adjustedDist);
    }

    outColor = vertexColor;
    outColor.a *= alpha;
}
