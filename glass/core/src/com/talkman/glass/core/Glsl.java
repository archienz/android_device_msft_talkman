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

package com.talkman.glass.core;

import android.content.Context;
import android.opengl.GLES31;
import android.util.Log;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

/**
 * GLES 3.1 program helper. Prefers {@code glass/core/shaders/*.glsl} packaged
 * as jar resources or APK assets; falls back to the in-class copies.
 */
final class Glsl {
    static final String TAG = "TalkmanGlass";

    static final String GLASS_VERT = "glass.vert.glsl";
    static final String GLASS_FRAG = "glass.frag.glsl";
    static final String KAWASE_VERT = "kawase.vert.glsl";
    static final String KAWASE_FRAG = "kawase.frag.glsl";

    private Glsl() {}

    static String load(Context context, String fileName) {
        InputStream in = open(context, fileName);
        if (in != null) {
            try {
                return readUtf8(in);
            } catch (IOException e) {
                Log.w(TAG, "shader stream " + fileName, e);
            } finally {
                try {
                    in.close();
                } catch (IOException ignored) {
                }
            }
        }
        String embedded = embedded(fileName);
        if (embedded != null) {
            return embedded;
        }
        Log.e(TAG, "missing shader " + fileName);
        return "void main() {}";
    }

    static int link(String vertSrc, String fragSrc, String label) {
        int vs = compile(GLES31.GL_VERTEX_SHADER, vertSrc, label + ".vert");
        int fs = compile(GLES31.GL_FRAGMENT_SHADER, fragSrc, label + ".frag");
        if (vs == 0 || fs == 0) {
            if (vs != 0) {
                GLES31.glDeleteShader(vs);
            }
            if (fs != 0) {
                GLES31.glDeleteShader(fs);
            }
            return 0;
        }
        int prog = GLES31.glCreateProgram();
        GLES31.glAttachShader(prog, vs);
        GLES31.glAttachShader(prog, fs);
        GLES31.glLinkProgram(prog);
        GLES31.glDeleteShader(vs);
        GLES31.glDeleteShader(fs);
        int[] ok = new int[1];
        GLES31.glGetProgramiv(prog, GLES31.GL_LINK_STATUS, ok, 0);
        if (ok[0] == 0) {
            Log.e(TAG, label + " link: " + GLES31.glGetProgramInfoLog(prog));
            GLES31.glDeleteProgram(prog);
            return 0;
        }
        return prog;
    }

    static int compile(int type, String source, String label) {
        int shader = GLES31.glCreateShader(type);
        GLES31.glShaderSource(shader, source);
        GLES31.glCompileShader(shader);
        int[] ok = new int[1];
        GLES31.glGetShaderiv(shader, GLES31.GL_COMPILE_STATUS, ok, 0);
        if (ok[0] == 0) {
            Log.e(TAG, label + " compile: " + GLES31.glGetShaderInfoLog(shader));
            GLES31.glDeleteShader(shader);
            return 0;
        }
        return shader;
    }

    static void deleteProgram(int prog) {
        if (prog != 0) {
            GLES31.glDeleteProgram(prog);
        }
    }

    static int createVbo(float[] verts) {
        FloatBuffer fb = ByteBuffer.allocateDirect(verts.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        fb.put(verts).position(0);
        int[] id = new int[1];
        GLES31.glGenBuffers(1, id, 0);
        GLES31.glBindBuffer(GLES31.GL_ARRAY_BUFFER, id[0]);
        GLES31.glBufferData(GLES31.GL_ARRAY_BUFFER, verts.length * 4, fb,
                GLES31.GL_STATIC_DRAW);
        GLES31.glBindBuffer(GLES31.GL_ARRAY_BUFFER, 0);
        return id[0];
    }

    static int createVao() {
        int[] id = new int[1];
        GLES31.glGenVertexArrays(1, id, 0);
        return id[0];
    }

    static void bindUnitQuad(int vao, int vbo) {
        GLES31.glBindVertexArray(vao);
        GLES31.glBindBuffer(GLES31.GL_ARRAY_BUFFER, vbo);
        GLES31.glEnableVertexAttribArray(0);
        GLES31.glVertexAttribPointer(0, 2, GLES31.GL_FLOAT, false, 8, 0);
    }

    static void deleteBuffer(int id) {
        if (id != 0) {
            GLES31.glDeleteBuffers(1, new int[] {id}, 0);
        }
    }

    static void deleteVao(int id) {
        if (id != 0) {
            GLES31.glDeleteVertexArrays(1, new int[] {id}, 0);
        }
    }

    static boolean check(String where) {
        int err = GLES31.glGetError();
        if (err != GLES31.GL_NO_ERROR) {
            Log.e(TAG, where + " glError 0x" + Integer.toHexString(err));
            return false;
        }
        return true;
    }

    private static InputStream open(Context context, String fileName) {
        InputStream in = Glsl.class.getResourceAsStream("/" + fileName);
        if (in != null) {
            return in;
        }
        in = Glsl.class.getResourceAsStream("/shaders/" + fileName);
        if (in != null) {
            return in;
        }
        if (context != null) {
            try {
                return context.getAssets().open("shaders/" + fileName);
            } catch (IOException ignored) {
            }
        }
        return null;
    }

    private static String readUtf8(InputStream in) throws IOException {
        ByteArrayOutputStream out = new ByteArrayOutputStream(2048);
        byte[] buf = new byte[512];
        int n;
        while ((n = in.read(buf)) >= 0) {
            out.write(buf, 0, n);
        }
        return out.toString("UTF-8");
    }

    private static String embedded(String fileName) {
        if (GLASS_VERT.equals(fileName)) {
            return EMBED_GLASS_VERT;
        }
        if (GLASS_FRAG.equals(fileName)) {
            return EMBED_GLASS_FRAG;
        }
        if (KAWASE_VERT.equals(fileName)) {
            return EMBED_KAWASE_VERT;
        }
        if (KAWASE_FRAG.equals(fileName)) {
            return EMBED_KAWASE_FRAG;
        }
        return null;
    }

    // Keep in sync with glass/core/shaders/*.glsl
    private static final String EMBED_GLASS_VERT =
            "#version 310 es\n"
            + "precision highp float;\n"
            + "layout(location = 0) in vec2 aPos;\n"
            + "uniform vec4 uRect;\n"
            + "uniform vec2 uResolution;\n"
            + "out vec2 vUv;\n"
            + "out vec2 vPixel;\n"
            + "void main() {\n"
            + "    vec2 pad = vec2(2.0) / max(uResolution, vec2(1.0));\n"
            + "    vec2 origin = uRect.xy - pad;\n"
            + "    vec2 extent = uRect.zw + pad * 2.0;\n"
            + "    vec2 n = origin + aPos * extent;\n"
            + "    vUv = n;\n"
            + "    vPixel = n * uResolution;\n"
            + "    vec2 clip = vec2(n.x * 2.0 - 1.0, 1.0 - n.y * 2.0);\n"
            + "    gl_Position = vec4(clip, 0.0, 1.0);\n"
            + "}\n";

    private static final String EMBED_GLASS_FRAG =
            "#version 310 es\n"
            + "precision highp float;\n"
            + "\n"
            + "// Talkman liquid glass. Original GLES 3.1 for Adreno 418.\n"
            + "// Convex slab + rim, IOR bend, RGB split, two-octave flow.\n"
            + "// Not derived from GlassiFy.js or LiquidGlassKit.\n"
            + "\n"
            + "uniform mediump sampler2D uTex;\n"
            + "uniform float uIor;\n"
            + "uniform float uDispersion;\n"
            + "uniform float uFresnel;\n"
            + "uniform float uRadius;\n"
            + "uniform float uBevel;\n"
            + "uniform float uWarp;\n"
            + "uniform float uTime;\n"
            + "uniform vec2 uResolution;\n"
            + "uniform vec4 uRect;\n"
            + "\n"
            + "in vec2 vUv;\n"
            + "in vec2 vPixel;\n"
            + "layout(location = 0) out vec4 fragColor;\n"
            + "\n"
            + "float sdRoundBox(vec2 p, vec2 halfExt, float radius) {\n"
            + "    vec2 q = abs(p) - halfExt + radius;\n"
            + "    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - radius;\n"
            + "}\n"
            + "\n"
            + "float hash21(vec2 p) {\n"
            + "    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);\n"
            + "}\n"
            + "\n"
            + "float vnoise(vec2 p) {\n"
            + "    vec2 i = floor(p);\n"
            + "    vec2 f = fract(p);\n"
            + "    f = f * f * (3.0 - 2.0 * f);\n"
            + "    float a = hash21(i);\n"
            + "    float b = hash21(i + vec2(1.0, 0.0));\n"
            + "    float c = hash21(i + vec2(0.0, 1.0));\n"
            + "    float d = hash21(i + vec2(1.0, 1.0));\n"
            + "    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);\n"
            + "}\n"
            + "\n"
            + "float fbm(vec2 p) {\n"
            + "    return vnoise(p) * 0.62 + vnoise(p * 2.17 + 3.1) * 0.38;\n"
            + "}\n"
            + "\n"
            + "float slabHeight(vec2 p, vec2 halfExt, float rad, float bevel) {\n"
            + "    float d = sdRoundBox(p, halfExt, rad);\n"
            + "    float span = max(min(halfExt.x, halfExt.y), 8.0);\n"
            + "    float nd = clamp(-d / span, 0.0, 1.0);\n"
            + "    float dome = pow(nd, 0.46);\n"
            + "    float lip = exp(-abs(d) * 2.8 / max(bevel, 1.0));\n"
            + "    return dome * 0.78 + lip * 0.62;\n"
            + "}\n"
            + "\n"
            + "void main() {\n"
            + "    vec2 halfExt = uRect.zw * uResolution * 0.5;\n"
            + "    vec2 center = (uRect.xy + uRect.zw * 0.5) * uResolution;\n"
            + "    vec2 p = vPixel - center;\n"
            + "    float rad = min(uRadius, min(halfExt.x, halfExt.y) - 1.0);\n"
            + "    float d = sdRoundBox(p, halfExt, rad);\n"
            + "    float mask = 1.0 - smoothstep(-1.4, 1.4, d);\n"
            + "    float bw = max(uBevel, 1.0);\n"
            + "    float h = slabHeight(p, halfExt, rad, bw);\n"
            + "\n"
            + "    float e = 2.25;\n"
            + "    float hL = slabHeight(p - vec2(e, 0.0), halfExt, rad, bw);\n"
            + "    float hR = slabHeight(p + vec2(e, 0.0), halfExt, rad, bw);\n"
            + "    float hD = slabHeight(p - vec2(0.0, e), halfExt, rad, bw);\n"
            + "    float hU = slabHeight(p + vec2(0.0, e), halfExt, rad, bw);\n"
            + "    vec2 slope = vec2(hL - hR, hD - hU);\n"
            + "    vec2 n2 = normalize(slope + vec2(1.0e-5));\n"
            + "    float tilt = clamp(length(slope) * 1.15, 0.0, 1.0);\n"
            + "    vec3 N = normalize(vec3(n2 * (0.35 + 1.55 * tilt), 1.0 - tilt * 0.42));\n"
            + "\n"
            + "    vec3 I = vec3(0.0, 0.0, -1.0);\n"
            + "    float eta = 1.0 / max(uIor, 1.001);\n"
            + "    vec3 T = refract(I, N, eta);\n"
            + "    float live = step(1.0e-4, dot(T, T));\n"
            + "    vec2 refr = mix(n2 * 0.22, T.xy, live);\n"
            + "\n"
            + "    float warp = max(uWarp, 0.0);\n"
            + "    vec2 lens = (p / max(uResolution, vec2(1.0))) * (-0.40 * warp * h);\n"
            + "    vec2 edge = refr * ((uIor - 1.0) * 0.18 * warp);\n"
            + "\n"
            + "    vec2 flowUv = vUv * vec2(2.1, 2.8);\n"
            + "    float t = uTime;\n"
            + "    vec2 flow = vec2(\n"
            + "            fbm(flowUv + vec2(t * 0.22, -t * 0.11)),\n"
            + "            fbm(flowUv.yx + vec2(-t * 0.16, t * 0.19))) - 0.5;\n"
            + "    vec2 offset = clamp(lens + edge + flow * (0.055 * warp), vec2(-0.09), vec2(0.09));\n"
            + "\n"
            + "    float span = max(min(halfExt.x, halfExt.y), 8.0);\n"
            + "    float edgeAmt = 1.0 - clamp(-d / span, 0.0, 1.0);\n"
            + "    float prism = uDispersion * (0.004 + 0.018 * edgeAmt * edgeAmt) * warp;\n"
            + "    vec2 chroma = normalize(offset + n2 * 0.002 + vec2(1.0e-4));\n"
            + "    vec2 baseUv = clamp(vUv - offset, 0.0, 1.0);\n"
            + "    vec2 tap = 2.8 / max(uResolution, vec2(1.0));\n"
            + "    vec3 col = vec3(0.0);\n"
            + "    vec2 u0 = baseUv;\n"
            + "    vec2 u1 = clamp(baseUv + vec2(tap.x, 0.0), 0.0, 1.0);\n"
            + "    vec2 u2 = clamp(baseUv + vec2(-tap.x, 0.0), 0.0, 1.0);\n"
            + "    vec2 u3 = clamp(baseUv + vec2(0.0, tap.y), 0.0, 1.0);\n"
            + "    vec2 u4 = clamp(baseUv + vec2(0.0, -tap.y), 0.0, 1.0);\n"
            + "    col += vec3(texture(uTex, clamp(u0 - chroma * prism, 0.0, 1.0)).r,\n"
            + "            texture(uTex, u0).g,\n"
            + "            texture(uTex, clamp(u0 + chroma * prism, 0.0, 1.0)).b);\n"
            + "    col += vec3(texture(uTex, clamp(u1 - chroma * prism, 0.0, 1.0)).r,\n"
            + "            texture(uTex, u1).g,\n"
            + "            texture(uTex, clamp(u1 + chroma * prism, 0.0, 1.0)).b);\n"
            + "    col += vec3(texture(uTex, clamp(u2 - chroma * prism, 0.0, 1.0)).r,\n"
            + "            texture(uTex, u2).g,\n"
            + "            texture(uTex, clamp(u2 + chroma * prism, 0.0, 1.0)).b);\n"
            + "    col += vec3(texture(uTex, clamp(u3 - chroma * prism, 0.0, 1.0)).r,\n"
            + "            texture(uTex, u3).g,\n"
            + "            texture(uTex, clamp(u3 + chroma * prism, 0.0, 1.0)).b);\n"
            + "    col += vec3(texture(uTex, clamp(u4 - chroma * prism, 0.0, 1.0)).r,\n"
            + "            texture(uTex, u4).g,\n"
            + "            texture(uTex, clamp(u4 + chroma * prism, 0.0, 1.0)).b);\n"
            + "    col *= 0.224;\n"
            + "\n"
            + "    vec3 V = vec3(0.0, 0.0, 1.0);\n"
            + "    float nv = max(dot(N, V), 0.0);\n"
            + "    float fres = 0.03 + 0.97 * pow(1.0 - nv, 4.0);\n"
            + "    fres *= uFresnel;\n"
            + "    vec3 ink = vec3(0.910, 0.910, 0.910);\n"
            + "    vec3 rim = ink * fres * (0.18 + 0.82 * edgeAmt);\n"
            + "\n"
            + "    vec3 L = normalize(vec3(-0.42, 0.78, 0.46));\n"
            + "    vec3 H = normalize(L + V);\n"
            + "    float spec = pow(max(dot(N, H), 0.0), 42.0);\n"
            + "    float streak = spec * exp(-7.5 * abs(n2.x * 0.4 + n2.y * 0.9 - 0.08));\n"
            + "    vec3 glint = ink * streak * (0.35 + 0.65 * h);\n"
            + "\n"
            + "    float hair = (1.0 - smoothstep(0.0, 1.2, abs(d))) * 0.28;\n"
            + "    vec3 outc = col + rim + glint + vec3(hair);\n"
            + "\n"
            + "    fragColor = vec4(outc, mask);\n"
            + "}\n";

    private static final String EMBED_KAWASE_VERT =
            "#version 310 es\n"
            + "precision mediump float;\n"
            + "layout(location = 0) in vec2 aPos;\n"
            + "void main() {\n"
            + "    gl_Position = vec4(aPos, 0.0, 1.0);\n"
            + "}\n";

    private static final String EMBED_KAWASE_FRAG =
            "#version 310 es\n"
            + "precision mediump float;\n"
            + "uniform mediump sampler2D uTex;\n"
            + "uniform vec2 uHalfPixel;\n"
            + "uniform vec2 uDstSize;\n"
            + "uniform vec2 uUvScale;\n"
            + "uniform float uMode;\n"
            + "layout(location = 0) out vec4 fragColor;\n"
            + "void main() {\n"
            + "    vec2 uv = (gl_FragCoord.xy / max(uDstSize, vec2(1.0))) * uUvScale;\n"
            + "    vec2 hp = uHalfPixel;\n"
            + "    vec4 down = texture(uTex, uv) * 4.0;\n"
            + "    down += texture(uTex, uv - hp);\n"
            + "    down += texture(uTex, uv + hp);\n"
            + "    down += texture(uTex, uv + vec2(hp.x, -hp.y));\n"
            + "    down += texture(uTex, uv - vec2(hp.x, -hp.y));\n"
            + "    down *= 0.125;\n"
            + "    vec4 up = texture(uTex, uv + vec2(-hp.x * 2.0, 0.0));\n"
            + "    up += texture(uTex, uv + vec2(-hp.x, hp.y)) * 2.0;\n"
            + "    up += texture(uTex, uv + vec2(0.0, hp.y * 2.0));\n"
            + "    up += texture(uTex, uv + vec2(hp.x, hp.y)) * 2.0;\n"
            + "    up += texture(uTex, uv + vec2(hp.x * 2.0, 0.0));\n"
            + "    up += texture(uTex, uv + vec2(hp.x, -hp.y)) * 2.0;\n"
            + "    up += texture(uTex, uv + vec2(0.0, -hp.y * 2.0));\n"
            + "    up += texture(uTex, uv + vec2(-hp.x, -hp.y)) * 2.0;\n"
            + "    up *= (1.0 / 12.0);\n"
            + "    fragColor = mix(down, up, uMode);\n"
            + "}\n";
}
