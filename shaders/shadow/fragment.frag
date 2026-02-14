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

    // Calculate alpha based on distance and blur. Keep the edge fully opaque
    // so the element AA edge does not reveal a bright seam.
    float aa = max(fwidth(adjustedDist), 0.0001);
    float alpha;
    if (blur > 0.0) {
        // Smooth falloff from the edge outward over the blur radius.
        alpha = 1.0 - smoothstep(0.0, blur + aa, adjustedDist);
    } else {
        // Anti-aliased hard edge when no blur.
        alpha = 1.0 - smoothstep(0.0, aa, adjustedDist);
    }

    // Keep only the region outside the original element so transparent
    // elements do not have their interior filled by the shadow.
    vec2 elementLocalPos = p - elementOffset;
    vec2 eq = abs(elementLocalPos) - elementSize * 0.5 + r;
    float dElement = length(max(eq, 0.0)) + min(max(eq.x, eq.y), 0.0) - r;
    float shapeAa = max(fwidth(dElement), 0.0001);
    // Push the cutout transition one AA-width inward so shadow coverage stays
    // solid under the element's outer AA fringe, avoiding a bright halo.
    float outsideMask = smoothstep(-2.0 * shapeAa, -shapeAa, dElement);
    alpha *= outsideMask;

    outColor = vertexColor;
    outColor.a *= alpha;
}
