#version 450

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in float borderRadius;
layout(location = 2) in vec4 localPos;
layout(location = 3) in vec2 size;
layout(location = 4) in vec2 elementSize;
layout(location = 5) in float blur;
layout(location = 6) in float spread;
layout(location = 7) in vec2 elementOffset;

layout(location = 0) out vec4 outColor;

// This uses an SDF for the shadow instead of matching the browser exactly with
// Gaussian Blur. This is an honest trade-off here, and we can switch to
// gaussian blur in the future, but that would increase the complexity of this
// shader by quite a bit as far as I can tell.
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

    // Calculate shadow coverage from distance and blur.
    float alpha;
    if (blur > 0.0) {
        float aa = max(fwidth(adjustedDist), 0.0001);
        // Smooth falloff from inside to outside over the blur radius.
        alpha = 1.0 - smoothstep(-aa - blur, aa + blur, adjustedDist);
    } else {
        // Anti-aliased hard edge when no blur.
        alpha = clamp(0.5 - adjustedDist, 0.0, 1.0);
    }

    // Keep only the region outside the original element so transparent
    // elements do not have their interior filled by the shadow.
    vec2 elementLocalPos = p - elementOffset;
    vec2 eq = abs(elementLocalPos) - elementSize * 0.5 + r;
    float dElement = length(max(eq, 0.0)) + min(max(eq.x, eq.y), 0.0) - r;
    float elementCutout = clamp(0.5 - dElement, 0.0, 1.0);
    alpha = max(alpha - elementCutout, 0.0);

    outColor = vertexColor;
    outColor.a *= alpha;
}
