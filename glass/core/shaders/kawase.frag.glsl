#version 310 es
precision mediump float;

// Dual-Kawase down/up (published filter). One program, uMode selects kernel.
// mediump, mix instead of a branch. Samples stay on the 360x640 cache.

uniform mediump sampler2D uTex;
uniform vec2 uHalfPixel;
uniform vec2 uDstSize;
uniform vec2 uUvScale;
uniform float uMode;

layout(location = 0) out vec4 fragColor;

void main() {
    vec2 uv = (gl_FragCoord.xy / max(uDstSize, vec2(1.0))) * uUvScale;
    vec2 hp = uHalfPixel;

    vec4 down = texture(uTex, uv) * 4.0;
    down += texture(uTex, uv - hp);
    down += texture(uTex, uv + hp);
    down += texture(uTex, uv + vec2(hp.x, -hp.y));
    down += texture(uTex, uv - vec2(hp.x, -hp.y));
    down *= 0.125;

    vec4 up = texture(uTex, uv + vec2(-hp.x * 2.0, 0.0));
    up += texture(uTex, uv + vec2(-hp.x, hp.y)) * 2.0;
    up += texture(uTex, uv + vec2(0.0, hp.y * 2.0));
    up += texture(uTex, uv + vec2(hp.x, hp.y)) * 2.0;
    up += texture(uTex, uv + vec2(hp.x * 2.0, 0.0));
    up += texture(uTex, uv + vec2(hp.x, -hp.y)) * 2.0;
    up += texture(uTex, uv + vec2(0.0, -hp.y * 2.0));
    up += texture(uTex, uv + vec2(-hp.x, -hp.y)) * 2.0;
    up *= (1.0 / 12.0);

    fragColor = mix(down, up, uMode);
}
