#version 450

layout(location = 0) in vec2 fragUV;
layout(location = 0) out vec4 outColor;

layout(set = 0, binding = 0) uniform sampler2D fontAtlas;

layout(push_constant) uniform PC {
    vec2 screenSize;
    vec2 offset;
} pc;

void main() {
    float alpha = texture(fontAtlas, fragUV).r;
    if (alpha < 0.01) discard;
    outColor = vec4(1.0, 1.0, 1.0, alpha);
}
