#version 450

layout(location = 0) in vec2 inUV;
layout(location = 0) out vec4 outColor;

// The linear-light FP16 offscreen render target.
layout(set = 0, binding = 0) uniform sampler2D offscreenLinear;

// 0 = sRGB/SDR output, 1 = HDR10 PQ (ST2084) output
layout(push_constant) uniform PushConstants {
    uint hdrMode;
} pc;

// ---- sRGB output transform ----
float linearToSrgbChannel(float v) {
    if (v <= 0.0031308) return v * 12.92;
    return 1.055 * pow(v, 1.0 / 2.4) - 0.055;
}

vec3 linearToSrgb(vec3 c) {
    return vec3(
        linearToSrgbChannel(c.r),
        linearToSrgbChannel(c.g),
        linearToSrgbChannel(c.b)
    );
}

// ---- HDR10 / PQ (ST 2084) output transform ----
// Input: linear-light BT.709 tristimulus in [0, 1] where 1 == 100 cd/m².
// The matrix rotates to BT.2020 primaries, then applies PQ EOTF-1.
//
// Bright UI elements are assumed to live at SDR level (0..1 maps to 0..100 nits).
// If you want peak HDR elements (e.g. bright highlights) push them above 1.0 in
// the linear scene before the present pass.

// BT.709 -> BT.2020 colour-primary matrix
vec3 bt709ToBt2020(vec3 c) {
    return vec3(
         0.627402  * c.r + 0.329292 * c.g + 0.043306 * c.b,
         0.069095  * c.r + 0.919544 * c.g + 0.011360 * c.b,
         0.016394  * c.r + 0.088028 * c.g + 0.895578 * c.b
    );
}

// ST 2084 PQ EOTF-inverse — maps linear scene luminance (0..1) to PQ signal.
// maxLuminance is the reference white in nits; 203 nits is the HGiG/HDR10 SDR
// reference white so sRGB content maps cleanly without looking washed out.
float linearToPq(float Lin) {
    const float maxLuminance = 10000.0;
    const float sdrWhiteNits = 203.0;
    // Scale so that input 1.0 → sdrWhiteNits nits.
    float Y = Lin * sdrWhiteNits / maxLuminance;
    Y = clamp(Y, 0.0, 1.0);

    const float m1 = 0.1593017578125;
    const float m2 = 78.84375;
    const float c1 = 0.8359375;
    const float c2 = 18.8515625;
    const float c3 = 18.6875;

    float Ym1 = pow(Y, m1);
    return pow((c1 + c2 * Ym1) / (1.0 + c3 * Ym1), m2);
}

vec3 linearToPqColor(vec3 c) {
    return vec3(linearToPq(c.r), linearToPq(c.g), linearToPq(c.b));
}

void main() {
    vec4 linear = texture(offscreenLinear, inUV);

    vec3 rgb;
    if (pc.hdrMode == 1u) {
        // HDR10 / ST2084 path
        vec3 bt2020 = bt709ToBt2020(linear.rgb);
        rgb = linearToPqColor(bt2020);
    } else {
        // SDR / sRGB path
        rgb = linearToSrgb(linear.rgb);
    }

    outColor = vec4(rgb, linear.a);
}
