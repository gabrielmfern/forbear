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

    vec4 distanceToEdges = vec4(
            // top
            abs(p.y - (-size.y * 0.5)),
            // bottom,
            abs(p.y - size.y * 0.5),
            // left
            abs(p.x - (-size.x * 0.5)),
            // right
            abs(p.x - size.x * 0.5)
        );

    if (distanceToEdges.x <= borderSize.x ||
            distanceToEdges.y <= borderSize.y ||
            distanceToEdges.z <= borderSize.z ||
            distanceToEdges.w <= borderSize.w) {
        outColor = mix(outColor, borderColor, borderColor.a);
    }
}
