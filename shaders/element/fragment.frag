#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in float borderRadius;
layout(location = 2) in vec4 localPos;
layout(location = 3) in vec2 size;
layout(location = 4) in flat int imageIndex;
layout(location = 5) in vec4 borderColor;
layout(location = 6) in vec4 borderSize;
layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 1) uniform sampler2D textures[];

void main() {
    vec2 p = (localPos.xy - 0.5) * size;
    float r = min(borderRadius, min(size.x, size.y) * 0.5);

    // SDF for rounded rectangle
    vec2 q = abs(p) - size * 0.5 + r;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;

    vec4 color = vertexColor;
    if (imageIndex >= 0) {
        color *= texture(textures[nonuniformEXT(imageIndex)], localPos.xy);
    }

    outColor = color;
    outColor.a *= step(d, 0.0);

    if (step(d, 0.0) == 0.0) discard;

    // Calculate distance to each edge (for non-corner regions)
    vec4 distanceToEdges = vec4(
            // top
            abs(p.y - (-size.y * 0.5)),
            // bottom
            abs(p.y - size.y * 0.5),
            // left
            abs(p.x - (-size.x * 0.5)),
            // right
            abs(p.x - size.x * 0.5)
        );

    // Check if we're in the border region using both approaches:
    // 1. SDF-based for corners (follows the rounded edge)
    // 2. Edge-based for straight sections (allows different border widths per side)
    
    // For corners: use SDF with the minimum border width
    float minBorderWidth = min(min(borderSize.x, borderSize.y), min(borderSize.z, borderSize.w));
    bool inCornerBorder = d > -minBorderWidth && minBorderWidth > 0.0;
    
    // For straight edges: check if we're within the border width of each edge
    // but outside the corner regions
    bool inCornerRegion = (abs(p.x) > size.x * 0.5 - r) && (abs(p.y) > size.y * 0.5 - r);
    
    bool inEdgeBorder = !inCornerRegion && (
        distanceToEdges.x <= borderSize.x ||
        distanceToEdges.y <= borderSize.y ||
        distanceToEdges.z <= borderSize.z ||
        distanceToEdges.w <= borderSize.w
    );
    
    if ((inCornerRegion && inCornerBorder) || inEdgeBorder) {
        outColor = mix(outColor, borderColor, borderColor.a);
    }
}
