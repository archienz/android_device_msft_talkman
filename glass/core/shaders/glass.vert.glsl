#version 310 es
precision highp float;

// Talkman glass panel quad. Original GLES -- not LiquidGlassKit Metal/Swift.
// aPos is the unit square (0..1) for a triangle strip.

layout(location = 0) in vec2 aPos;

uniform vec4 uRect;
uniform vec2 uResolution;

out vec2 vUv;
out vec2 vPixel;

void main() {
    vec2 pad = vec2(2.0) / max(uResolution, vec2(1.0));
    vec2 origin = uRect.xy - pad;
    vec2 extent = uRect.zw + pad * 2.0;
    vec2 n = origin + aPos * extent;
    vUv = n;
    vPixel = n * uResolution;
    vec2 clip = vec2(n.x * 2.0 - 1.0, 1.0 - n.y * 2.0);
    gl_Position = vec4(clip, 0.0, 1.0);
}
