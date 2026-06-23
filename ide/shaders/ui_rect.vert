#version 450

layout(push_constant) uniform PC {
    vec2 screenSize;
    vec2 offset;
} pc;

layout(location = 0) in vec2 inPos;
layout(location = 1) in vec4 inColor;

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 ndc = (inPos + pc.offset) / pc.screenSize * 2.0 - 1.0;
    gl_Position = vec4(ndc.x, -ndc.y, 0.0, 1.0);
    fragColor = inColor;
}
