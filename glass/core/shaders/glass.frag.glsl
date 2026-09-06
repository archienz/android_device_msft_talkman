#version 310 es
precision highp float;

// Talkman liquid glass. Original GLES 3.1 for Adreno 418.
// Convex slab + rim, IOR bend, RGB split, two-octave flow.
// Not derived from GlassiFy.js or LiquidGlassKit.

uniform mediump sampler2D uTex;
uniform float uIor;
uniform float uDispersion;
uniform float uFresnel;
uniform float uRadius;
uniform float uBevel;
uniform float uWarp;
uniform float uTime;
uniform vec2 uResolution;
uniform vec4 uRect;

in vec2 vUv;
in vec2 vPixel;
layout(location = 0) out vec4 fragColor;

float sdRoundBox(vec2 p, vec2 halfExt, float radius) {
    vec2 q = abs(p) - halfExt + radius;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;
}

float hash21(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    return vnoise(p) * 0.62 + vnoise(p * 2.17 + 3.1) * 0.38;
}

float slabHeight(vec2 p, vec2 halfExt, float rad, float bevel) {
    float d = sdRoundBox(p, halfExt, rad);
    float span = max(min(halfExt.x, halfExt.y), 8.0);
    float nd = clamp(-d / span, 0.0, 1.0);
    float dome = pow(nd, 0.46);
    float lip = exp(-abs(d) * 2.8 / max(bevel, 1.0));
    return dome * 0.78 + lip * 0.62;
}

void main() {
    vec2 halfExt = uRect.zw * uResolution * 0.5;
    vec2 center = (uRect.xy + uRect.zw * 0.5) * uResolution;
    vec2 p = vPixel - center;
    float rad = min(uRadius, min(halfExt.x, halfExt.y) - 1.0);
    float d = sdRoundBox(p, halfExt, rad);
    float mask = 1.0 - smoothstep(-1.4, 1.4, d);
    float bw = max(uBevel, 1.0);
    float h = slabHeight(p, halfExt, rad, bw);

    float e = 2.25;
    float hL = slabHeight(p - vec2(e, 0.0), halfExt, rad, bw);
    float hR = slabHeight(p + vec2(e, 0.0), halfExt, rad, bw);
    float hD = slabHeight(p - vec2(0.0, e), halfExt, rad, bw);
    float hU = slabHeight(p + vec2(0.0, e), halfExt, rad, bw);
    vec2 slope = vec2(hL - hR, hD - hU);
    vec2 n2 = normalize(slope + vec2(1.0e-5));
    float tilt = clamp(length(slope) * 1.15, 0.0, 1.0);
    vec3 N = normalize(vec3(n2 * (0.35 + 1.55 * tilt), 1.0 - tilt * 0.42));

    vec3 I = vec3(0.0, 0.0, -1.0);
    float eta = 1.0 / max(uIor, 1.001);
    vec3 T = refract(I, N, eta);
    float live = step(1.0e-4, dot(T, T));
    vec2 refr = mix(n2 * 0.22, T.xy, live);

    float warp = max(uWarp, 0.0);
    vec2 lens = (p / max(uResolution, vec2(1.0))) * (-0.40 * warp * h);
    vec2 edge = refr * ((uIor - 1.0) * 0.18 * warp);

    vec2 flowUv = vUv * vec2(2.1, 2.8);
    float t = uTime;
    vec2 flow = vec2(
            fbm(flowUv + vec2(t * 0.22, -t * 0.11)),
            fbm(flowUv.yx + vec2(-t * 0.16, t * 0.19))) - 0.5;
    vec2 offset = clamp(lens + edge + flow * (0.055 * warp), vec2(-0.09), vec2(0.09));

    float span = max(min(halfExt.x, halfExt.y), 8.0);
    float edgeAmt = 1.0 - clamp(-d / span, 0.0, 1.0);
    float prism = uDispersion * (0.004 + 0.018 * edgeAmt * edgeAmt) * warp;
    vec2 chroma = normalize(offset + n2 * 0.002 + vec2(1.0e-4));
    vec2 baseUv = clamp(vUv - offset, 0.0, 1.0);
    vec2 tap = 2.8 / max(uResolution, vec2(1.0));
    vec3 col = vec3(0.0);
    vec2 u0 = baseUv;
    vec2 u1 = clamp(baseUv + vec2(tap.x, 0.0), 0.0, 1.0);
    vec2 u2 = clamp(baseUv + vec2(-tap.x, 0.0), 0.0, 1.0);
    vec2 u3 = clamp(baseUv + vec2(0.0, tap.y), 0.0, 1.0);
    vec2 u4 = clamp(baseUv + vec2(0.0, -tap.y), 0.0, 1.0);
    col += vec3(texture(uTex, clamp(u0 - chroma * prism, 0.0, 1.0)).r,
            texture(uTex, u0).g,
            texture(uTex, clamp(u0 + chroma * prism, 0.0, 1.0)).b);
    col += vec3(texture(uTex, clamp(u1 - chroma * prism, 0.0, 1.0)).r,
            texture(uTex, u1).g,
            texture(uTex, clamp(u1 + chroma * prism, 0.0, 1.0)).b);
    col += vec3(texture(uTex, clamp(u2 - chroma * prism, 0.0, 1.0)).r,
            texture(uTex, u2).g,
            texture(uTex, clamp(u2 + chroma * prism, 0.0, 1.0)).b);
    col += vec3(texture(uTex, clamp(u3 - chroma * prism, 0.0, 1.0)).r,
            texture(uTex, u3).g,
            texture(uTex, clamp(u3 + chroma * prism, 0.0, 1.0)).b);
    col += vec3(texture(uTex, clamp(u4 - chroma * prism, 0.0, 1.0)).r,
            texture(uTex, u4).g,
            texture(uTex, clamp(u4 + chroma * prism, 0.0, 1.0)).b);
    col *= 0.224;

    vec3 V = vec3(0.0, 0.0, 1.0);
    float nv = max(dot(N, V), 0.0);
    float fres = 0.03 + 0.97 * pow(1.0 - nv, 4.0);
    fres *= uFresnel;
    vec3 ink = vec3(0.910, 0.910, 0.910);
    vec3 rim = ink * fres * (0.18 + 0.82 * edgeAmt);

    vec3 L = normalize(vec3(-0.42, 0.78, 0.46));
    vec3 H = normalize(L + V);
    float spec = pow(max(dot(N, H), 0.0), 42.0);
    float streak = spec * exp(-7.5 * abs(n2.x * 0.4 + n2.y * 0.9 - 0.08));
    vec3 glint = ink * streak * (0.35 + 0.65 * h);

    float hair = (1.0 - smoothstep(0.0, 1.2, abs(d))) * 0.28;
    vec3 outc = col + rim + glint + vec3(hair);

    fragColor = vec4(outc, mask);
}
