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

float sdfRoundRect(vec2 point, vec2 halfSize, float radius) {
    vec2 q = abs(point) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void main() {
    vec2 p = (localPos.xy - 0.5) * size;
    vec2 halfSize = size * 0.5;
    float rOuter = min(borderRadius, min(halfSize.x, halfSize.y));

    float dOuter = sdfRoundRect(p, halfSize, rOuter);
    float outerAa = fwidth(dOuter);
    float outerFill = 1.0 - smoothstep(-outerAa, outerAa, dOuter);

    vec4 color = vertexColor;
    if (imageIndex >= 0) {
        color *= texture(textures[nonuniformEXT(imageIndex)], localPos.xy);
    }

    float borderTop = borderSize.x;
    float borderBottom = borderSize.y;
    float borderLeft = borderSize.z;
    float borderRight = borderSize.w;

    vec2 innerSize = size - vec2(borderLeft + borderRight, borderTop + borderBottom);
    innerSize = max(innerSize, vec2(0.0));
    vec2 innerHalfSize = innerSize * 0.5;
    vec2 innerShift = vec2(borderLeft - borderRight, borderTop - borderBottom) * 0.5;
    vec2 innerPos = p - innerShift;

    float cornerInset = min(min(borderTop, borderBottom), min(borderLeft, borderRight));
    float rInner = max(rOuter - cornerInset, 0.0);
    rInner = min(rInner, min(innerHalfSize.x, innerHalfSize.y));

    float dInner = sdfRoundRect(innerPos, innerHalfSize, rInner);
    float innerAa = fwidth(dInner);
    float innerFill = 1.0 - smoothstep(-innerAa, innerAa, dInner);
    float hasInner = step(0.0001, min(innerSize.x, innerSize.y));
    innerFill *= hasInner;

    float mixFactor = clamp(innerFill / max(outerFill, 0.0001), 0.0, 1.0);
    outColor = mix(borderColor, color, mixFactor);
    outColor.a *= outerFill;
}
