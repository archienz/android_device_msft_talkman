#version 310 es
precision mediump float;

// Full-viewport triangle. aPos is already in clip space.

layout(location = 0) in vec2 aPos;

void main() {
    gl_Position = vec4(aPos, 0.0, 1.0);
}
