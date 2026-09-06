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

import android.opengl.GLES31;
import android.util.Log;

final class GlUtil {
    private static final String TAG = "TalkmanGlassCache";

    private GlUtil() {}

    static int compileShader(int type, String source) {
        int shader = GLES31.glCreateShader(type);
        GLES31.glShaderSource(shader, source);
        GLES31.glCompileShader(shader);
        int[] ok = new int[1];
        GLES31.glGetShaderiv(shader, GLES31.GL_COMPILE_STATUS, ok, 0);
        if (ok[0] == 0) {
            Log.e(TAG, "shader compile: " + GLES31.glGetShaderInfoLog(shader));
            GLES31.glDeleteShader(shader);
            return 0;
        }
        return shader;
    }

    static int linkProgram(String vertSrc, String fragSrc) {
        int vs = compileShader(GLES31.GL_VERTEX_SHADER, vertSrc);
        int fs = compileShader(GLES31.GL_FRAGMENT_SHADER, fragSrc);
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
        GLES31.glBindAttribLocation(prog, 0, "aPos");
        GLES31.glLinkProgram(prog);
        GLES31.glDeleteShader(vs);
        GLES31.glDeleteShader(fs);
        int[] ok = new int[1];
        GLES31.glGetProgramiv(prog, GLES31.GL_LINK_STATUS, ok, 0);
        if (ok[0] == 0) {
            Log.e(TAG, "program link: " + GLES31.glGetProgramInfoLog(prog));
            GLES31.glDeleteProgram(prog);
            return 0;
        }
        return prog;
    }

    static int createRgbaTexture(int width, int height) {
        int[] ids = new int[1];
        GLES31.glGenTextures(1, ids, 0);
        int id = ids[0];
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, id);
        GLES31.glTexParameteri(GLES31.GL_TEXTURE_2D, GLES31.GL_TEXTURE_MIN_FILTER,
                GLES31.GL_LINEAR);
        GLES31.glTexParameteri(GLES31.GL_TEXTURE_2D, GLES31.GL_TEXTURE_MAG_FILTER,
                GLES31.GL_LINEAR);
        GLES31.glTexParameteri(GLES31.GL_TEXTURE_2D, GLES31.GL_TEXTURE_WRAP_S,
                GLES31.GL_CLAMP_TO_EDGE);
        GLES31.glTexParameteri(GLES31.GL_TEXTURE_2D, GLES31.GL_TEXTURE_WRAP_T,
                GLES31.GL_CLAMP_TO_EDGE);
        GLES31.glTexImage2D(GLES31.GL_TEXTURE_2D, 0, GLES31.GL_RGBA, width, height, 0,
                GLES31.GL_RGBA, GLES31.GL_UNSIGNED_BYTE, null);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, 0);
        return id;
    }

    static void deleteTexture(int id) {
        if (id != 0) {
            GLES31.glDeleteTextures(1, new int[] {id}, 0);
        }
    }

    static boolean framebufferComplete() {
        int status = GLES31.glCheckFramebufferStatus(GLES31.GL_FRAMEBUFFER);
        if (status != GLES31.GL_FRAMEBUFFER_COMPLETE) {
            Log.e(TAG, "FBO incomplete: 0x" + Integer.toHexString(status));
            return false;
        }
        return true;
    }
}
