#version 450

layout(location = 0) in vec3 vertexPosition;
layout(location = 0) out vec4 vertexColor;
layout(location = 1) out float borderRadius;
layout(location = 2) out vec4 localPos;
layout(location = 3) out vec2 size;

layout(location = 4) out flat int imageIndex;
layout(location = 5) out vec4 borderColor;
layout(location = 6) out vec4 borderSize;
layout(location = 7) out flat uint blendMode;
layout(location = 8) out flat uint filterType;

struct ElementRenderingData {
    vec4 backgroundColor;
    vec4 borderColor;
    float borderRadius;
    vec4 borderSize;
    int imageIndex;
    int blendMode;
    uint filterType;
    mat4 modelViewProjectionMatrix;
    vec2 size;
};

layout(std430, set = 0, binding = 0) readonly buffer RenderingData {
    ElementRenderingData data[];
} renderingData;

void main() {
    ElementRenderingData d = renderingData.data[gl_InstanceIndex];

    gl_Position = d.modelViewProjectionMatrix * vec4(vertexPosition, 1.0);
    vertexColor = d.backgroundColor;
    borderSize = d.borderSize;
    borderColor = d.borderColor;
    borderRadius = d.borderRadius;
    size = d.size;
    localPos = vec4(vertexPosition, 1.0);
    imageIndex = d.imageIndex;
    blendMode = d.blendMode;
    filterType = d.filterType;
}
