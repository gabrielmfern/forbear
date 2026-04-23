#version 450
#extension GL_EXT_nonuniform_qualifier : enable

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in float borderRadius;
layout(location = 2) in vec4 localPos;
layout(location = 3) in vec2 size;
layout(location = 4) in flat int imageIndex;
layout(location = 5) in vec4 borderColor;
layout(location = 6) in vec4 borderSize;
layout(location = 7) in flat uint blendMode;
layout(location = 8) in flat uint filterType;
layout(location = 9) in flat int gradientStart;
layout(location = 10) in flat int gradientEnd;
layout(location = 11) in flat uint borderStyle;
layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 1) uniform sampler2D textures[];

struct GradientStop {
    vec4 color;
    float position;
};

layout(std430, set = 0, binding = 2) readonly buffer GradientStops {
    GradientStop stops[];
} gradientStops;

float sdfRoundRect(vec2 point, vec2 halfSize, float radius) {
    vec2 q = abs(point) - halfSize + radius;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

vec4 sampleGradient(float t) {
    int count = gradientEnd - gradientStart + 1;
    GradientStop first = gradientStops.stops[gradientStart];
    if (count <= 1 || t <= first.position) {
        return first.color;
    }
    for (int i = 0; i < count - 1; i++) {
        GradientStop curr = gradientStops.stops[gradientStart + i];
        GradientStop next = gradientStops.stops[gradientStart + i + 1];
        if (t <= next.position) {
            float denom = max(next.position - curr.position, 1e-6);
            float segmentT = clamp((t - curr.position) / denom, 0.0, 1.0);
            return mix(curr.color, next.color, segmentT);
        }
    }
    return gradientStops.stops[gradientEnd].color;
}

void main() {
    vec2 p = (localPos.xy - 0.5) * size;
    vec2 halfSize = size * 0.5;
    float rOuter = min(borderRadius, min(halfSize.x, halfSize.y));

    float dOuter = sdfRoundRect(p, halfSize, rOuter);
    float outerAa = max(fwidth(dOuter), 0.0001);
    float outerFill = 1.0 - smoothstep(-outerAa, outerAa, dOuter);

    vec4 color = vertexColor;
    if (gradientStart >= 0) {
        color = sampleGradient(localPos.x);
    }
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

    bool top = p.y < 0.0;
    bool left = p.x < 0.0;
    float cornerInset = top
        ? (left ? min(borderTop, borderLeft) : min(borderTop, borderRight))
        : (left ? min(borderBottom, borderLeft) : min(borderBottom, borderRight));
    float rInner = max(rOuter - cornerInset, 0.0);
    rInner = min(rInner, min(innerHalfSize.x, innerHalfSize.y));

    float dInner = sdfRoundRect(innerPos, innerHalfSize, rInner);
    float innerAa = max(fwidth(dInner), 0.0001);
    float innerFill = 1.0 - smoothstep(-innerAa, innerAa, dInner);
    float hasInner = step(0.0001, min(innerSize.x, innerSize.y));
    innerFill *= hasInner;

    float denom = max(max(outerFill, innerFill), 0.0001);
    float mixFactor = clamp(innerFill / denom, 0.0, 1.0);

    if (borderStyle == 1u && mixFactor < 1.0) {
        float edgePos;
        float dashSize;

        float distToTop = abs(p.y + halfSize.y);
        float distToBottom = abs(p.y - halfSize.y);
        float distToLeft = abs(p.x + halfSize.x);
        float distToRight = abs(p.x - halfSize.x);
        float minDist = min(min(distToTop, distToBottom), min(distToLeft, distToRight));

        if (minDist == distToTop) {
            edgePos = p.x + halfSize.x;
            dashSize = borderTop * 3.0;
        } else if (minDist == distToBottom) {
            edgePos = p.x + halfSize.x;
            dashSize = borderBottom * 3.0;
        } else if (minDist == distToLeft) {
            edgePos = p.y + halfSize.y;
            dashSize = borderLeft * 3.0;
        } else {
            edgePos = p.y + halfSize.y;
            dashSize = borderRight * 3.0;
        }

        if (dashSize > 0.0) {
            float pattern = mod(edgePos, dashSize * 2.0);
            if (pattern > dashSize) {
                mixFactor = 1.0;
            }
        }
    }

    outColor = mix(borderColor, color, mixFactor);
    outColor.a *= outerFill;

    // .grayscale is enum value 1 in node.zig.
    if (filterType == 1u) {
        float luminance = dot(outColor.rgb, vec3(0.2126, 0.7152, 0.0722));
        outColor.rgb = vec3(luminance);
    }

    // blendMode 0 = normal, 1 = multiply, 2 = darken (see BlendMode in node.zig).
    if (blendMode == 1u) {
        // Multiply: premultiply so dst*src + dst*(1-α) works correctly.
        outColor.rgb *= outColor.a;
    } else if (blendMode == 2u) {
        // Darken approximation: output mix(1, Cs, α) so that
        // min(mix(1, Cs, α), Cd) ≈ α·min(Cs, Cd) + (1-α)·Cd.
        // Exact at α=0 (→Cd) and α=1 (→min(Cs,Cd)); approximation in between.
        outColor.rgb = mix(vec3(1.0), outColor.rgb, outColor.a);
    }
}
