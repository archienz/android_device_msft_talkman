/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.talkman.glass.blur;

/**
 * Dual-Kawase GLSL ES 3.10 (mediump). No loops — each draw is one kernel.
 * Down / up are separate programs so Adreno 418 never takes a dynamic
 * iteration count in the fragment shader.
 */
final class KawaseShaders {
    private KawaseShaders() {}

    static final String VERT =
            "#version 310 es\n"
            + "precision mediump float;\n"
            + "layout(location = 0) in vec2 aPos;\n"
            + "out vec2 vUv;\n"
            + "void main() {\n"
            + "    vUv = aPos * 0.5 + 0.5;\n"
            + "    gl_Position = vec4(aPos, 0.0, 1.0);\n"
            + "}\n";

    /**
     * Dual-Kawase downsample (Strugar). {@code uFlipY} remaps Android bitmap
     * origin to GL on the first pass via mix (no branch).
     */
    static final String FRAG_DOWN =
            "#version 310 es\n"
            + "precision mediump float;\n"
            + "in vec2 vUv;\n"
            + "uniform mediump sampler2D uTex;\n"
            + "uniform vec2 uHalfPixel;\n"
            + "uniform float uFlipY;\n"
            + "out vec4 fragColor;\n"
            + "void main() {\n"
            + "    vec2 uv = vec2(vUv.x, mix(vUv.y, 1.0 - vUv.y, uFlipY));\n"
            + "    vec2 hp = uHalfPixel;\n"
            + "    vec4 sum = texture(uTex, uv) * 4.0;\n"
            + "    sum += texture(uTex, uv - hp);\n"
            + "    sum += texture(uTex, uv + hp);\n"
            + "    sum += texture(uTex, uv + vec2(hp.x, -hp.y));\n"
            + "    sum += texture(uTex, uv - vec2(hp.x, -hp.y));\n"
            + "    fragColor = sum * 0.125;\n"
            + "}\n";

    static final String FRAG_UP =
            "#version 310 es\n"
            + "precision mediump float;\n"
            + "in vec2 vUv;\n"
            + "uniform mediump sampler2D uTex;\n"
            + "uniform vec2 uHalfPixel;\n"
            + "out vec4 fragColor;\n"
            + "void main() {\n"
            + "    vec2 uv = vUv;\n"
            + "    vec2 hp = uHalfPixel;\n"
            + "    vec4 sum = texture(uTex, uv + vec2(-hp.x * 2.0, 0.0));\n"
            + "    sum += texture(uTex, uv + vec2(-hp.x, hp.y)) * 2.0;\n"
            + "    sum += texture(uTex, uv + vec2(0.0, hp.y * 2.0));\n"
            + "    sum += texture(uTex, uv + vec2(hp.x, hp.y)) * 2.0;\n"
            + "    sum += texture(uTex, uv + vec2(hp.x * 2.0, 0.0));\n"
            + "    sum += texture(uTex, uv + vec2(hp.x, -hp.y)) * 2.0;\n"
            + "    sum += texture(uTex, uv + vec2(0.0, -hp.y * 2.0));\n"
            + "    sum += texture(uTex, uv + vec2(-hp.x, -hp.y)) * 2.0;\n"
            + "    fragColor = sum * (1.0 / 12.0);\n"
            + "}\n";
}
