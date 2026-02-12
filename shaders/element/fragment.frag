#version 450
#extension GL_EXT_nonuniform_qualifier : enable

struct Stop {
    float start;
    vec4 color;
    int startIgnoring;
};

struct LinearGradient {
    float angle;
    Stop stops[16];
};

layout(location = 0) in vec4 vertexColor;
layout(location = 1) in float borderRadius;
layout(location = 2) in vec4 localPos;
layout(location = 3) in vec2 size;
layout(location = 4) in flat int imageIndex;
layout(location = 5) in vec4 borderColor;
layout(location = 6) in vec4 borderSize;
layout(location = 7) in flat LinearGradient gradient;

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
    float outerAa = max(fwidth(dOuter), 0.0001);
    float outerFill = 1.0 - smoothstep(-outerAa, outerAa, dOuter);

    vec4 color = vertexColor;
    if (imageIndex >= 0) {
        color *= texture(textures[nonuniformEXT(imageIndex)], localPos.xy);
    } else if (gradient.stops[0].startIgnoring == 0) {
        vec2 direction = normalize(vec2(cos(gradient.angle), sin(gradient.angle)));
        float projectionRange = dot(abs(direction), halfSize);
        float t = projectionRange > 0.0
            ? (dot(p, direction) + projectionRange) / (2.0 * projectionRange)
            : 0.0;
        t = clamp(t, 0.0, 1.0);

        Stop previous = gradient.stops[0];
        vec4 gradientColor = previous.color;

        if (t > previous.start) {
            bool foundSegment = false;

            for (int i = 1; i < 16; i += 1) {
                Stop current = gradient.stops[i];

                if (current.startIgnoring != 0) {
                    break;
                }

                if (t <= current.start) {
                    float segmentLength = max(current.start - previous.start, 0.0001);
                    float segmentT = clamp((t - previous.start) / segmentLength, 0.0, 1.0);
                    gradientColor = mix(previous.color, current.color, segmentT);
                    foundSegment = true;
                    break;
                }

                previous = current;
            }

            if (!foundSegment) {
                gradientColor = previous.color;
            }
        }

        color *= gradientColor;
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
    outColor = mix(borderColor, color, mixFactor);
    outColor.a *= outerFill;
}
