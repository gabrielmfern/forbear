#version 450

layout(location = 0) in vec3 vertexPosition;
layout(location = 0) out vec4 vertexColorForFrag;

struct ElementRenderingData {
    mat4 modelViewProjectionMatrix;
    vec4 backgroundColor;
};

layout(std430, set = 0, binding = 0) readonly buffer RenderingData {
    ElementRenderingData data[];
} renderingData;

void main() {
    ElementRenderingData d = renderingData.data[gl_InstanceIndex];
    gl_Position = d.modelViewProjectionMatrix * vec4(vertexPosition, 1.0);
    vertexColorForFrag = d.backgroundColor;
}
