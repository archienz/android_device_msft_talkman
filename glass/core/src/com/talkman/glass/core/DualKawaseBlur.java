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
import android.graphics.Bitmap;
import android.opengl.GLES31;
import android.opengl.GLUtils;
import android.util.Log;

/**
 * Dual-Kawase frost on the 360x640 cache. Three passes, one FBO, two
 * color textures (ping-pong). Never touches the 1440x2560 framebuffer.
 */
final class DualKawaseBlur {
    static final int CACHE_WIDTH = 360;
    static final int CACHE_HEIGHT = 640;

    private static final int HALF_W = CACHE_WIDTH / 2;
    private static final int HALF_H = CACHE_HEIGHT / 2;
    private static final int QUARTER_W = CACHE_WIDTH / 4;
    private static final int QUARTER_H = CACHE_HEIGHT / 4;

    private static final float[] NDC_TRI = {
            -1f, -1f,
            3f, -1f,
            -1f, 3f,
    };

    private int mFbo;
    private int mTexA;
    private int mTexB;
    private int mProg;
    private int mVao;
    private int mVbo;
    private int mResult;
    private int mUTex;
    private int mUHalfPixel;
    private int mUDstSize;
    private int mUUvScale;
    private int mUMode;
    private boolean mReady;

    void init(Context context) {
        // EGL context (re)create: prior names are already gone.
        forgetNames();
        mProg = Glsl.link(
                Glsl.load(context, Glsl.KAWASE_VERT),
                Glsl.load(context, Glsl.KAWASE_FRAG),
                "kawase");
        if (mProg == 0) {
            return;
        }
        mUTex = GLES31.glGetUniformLocation(mProg, "uTex");
        mUHalfPixel = GLES31.glGetUniformLocation(mProg, "uHalfPixel");
        mUDstSize = GLES31.glGetUniformLocation(mProg, "uDstSize");
        mUUvScale = GLES31.glGetUniformLocation(mProg, "uUvScale");
        mUMode = GLES31.glGetUniformLocation(mProg, "uMode");

        int[] ids = new int[2];
        GLES31.glGenTextures(2, ids, 0);
        mTexA = allocRgba(ids[0]);
        mTexB = allocRgba(ids[1]);

        int[] fbo = new int[1];
        GLES31.glGenFramebuffers(1, fbo, 0);
        mFbo = fbo[0];

        mVao = Glsl.createVao();
        mVbo = Glsl.createVbo(NDC_TRI);
        Glsl.bindUnitQuad(mVao, mVbo);
        GLES31.glBindBuffer(GLES31.GL_ARRAY_BUFFER, 0);
        GLES31.glBindVertexArray(0);

        mResult = mTexA;
        mReady = mTexA != 0 && mTexB != 0 && mFbo != 0;
        Glsl.check("kawase.init");
    }

    void release() {
        if (mProg != 0) {
            Glsl.deleteProgram(mProg);
        }
        if (mFbo != 0) {
            GLES31.glDeleteFramebuffers(1, new int[] {mFbo}, 0);
        }
        Glsl.deleteVao(mVao);
        Glsl.deleteBuffer(mVbo);
        if (mTexA != 0 || mTexB != 0) {
            GLES31.glDeleteTextures(2, new int[] {mTexA, mTexB}, 0);
        }
        forgetNames();
    }

    private void forgetNames() {
        mProg = 0;
        mFbo = 0;
        mVao = 0;
        mVbo = 0;
        mTexA = 0;
        mTexB = 0;
        mResult = 0;
        mReady = false;
    }

    boolean isReady() {
        return mReady;
    }

    int resultTexture() {
        return mResult;
    }

    /**
     * Upload a 360x640 (or any) bitmap and run down, down, up.
     */
    void rebuild(Bitmap src) {
        if (!mReady || src == null || src.isRecycled()) {
            return;
        }
        Bitmap scaled = src;
        boolean own = false;
        if (src.getWidth() != CACHE_WIDTH || src.getHeight() != CACHE_HEIGHT
                || src.getConfig() != Bitmap.Config.ARGB_8888) {
            scaled = Bitmap.createScaledBitmap(src, CACHE_WIDTH, CACHE_HEIGHT, true);
            own = scaled != src;
            if (scaled.getConfig() != Bitmap.Config.ARGB_8888) {
                Bitmap conv = scaled.copy(Bitmap.Config.ARGB_8888, false);
                if (own && scaled != src) {
                    scaled.recycle();
                }
                scaled = conv;
                own = true;
            }
        }

        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, mTexA);
        GLES31.glPixelStorei(GLES31.GL_UNPACK_ALIGNMENT, 1);
        GLUtils.texImage2D(GLES31.GL_TEXTURE_2D, 0, scaled, 0);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, 0);
        if (own && scaled != src && !scaled.isRecycled()) {
            scaled.recycle();
        }

        // Sharp cache. Dual-Kawase to 90x160 made a milk plate with no lens.
        mResult = mTexA;
        GLES31.glBindFramebuffer(GLES31.GL_FRAMEBUFFER, 0);
        Glsl.check("kawase.rebuild");
    }

    private void pass(int src, int dst, int dstW, int dstH, float uvSx, float uvSy,
            float mode) {
        GLES31.glBindFramebuffer(GLES31.GL_FRAMEBUFFER, mFbo);
        GLES31.glFramebufferTexture2D(GLES31.GL_FRAMEBUFFER, GLES31.GL_COLOR_ATTACHMENT0,
                GLES31.GL_TEXTURE_2D, dst, 0);
        int status = GLES31.glCheckFramebufferStatus(GLES31.GL_FRAMEBUFFER);
        if (status != GLES31.GL_FRAMEBUFFER_COMPLETE) {
            Log.e(Glsl.TAG, "kawase FBO 0x" + Integer.toHexString(status));
            return;
        }
        GLES31.glViewport(0, 0, dstW, dstH);
        GLES31.glUseProgram(mProg);
        GLES31.glActiveTexture(GLES31.GL_TEXTURE0);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, src);
        GLES31.glUniform1i(mUTex, 0);
        GLES31.glUniform2f(mUHalfPixel, 0.5f / CACHE_WIDTH, 0.5f / CACHE_HEIGHT);
        GLES31.glUniform2f(mUDstSize, dstW, dstH);
        GLES31.glUniform2f(mUUvScale, uvSx, uvSy);
        GLES31.glUniform1f(mUMode, mode);
        Glsl.bindUnitQuad(mVao, mVbo);
        GLES31.glDrawArrays(GLES31.GL_TRIANGLES, 0, 3);
        GLES31.glBindVertexArray(0);
        GLES31.glBindBuffer(GLES31.GL_ARRAY_BUFFER, 0);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, 0);
        GLES31.glUseProgram(0);
    }

    private static int allocRgba(int id) {
        if (id == 0) {
            return 0;
        }
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, id);
        GLES31.glTexParameteri(GLES31.GL_TEXTURE_2D, GLES31.GL_TEXTURE_MIN_FILTER,
                GLES31.GL_LINEAR);
        GLES31.glTexParameteri(GLES31.GL_TEXTURE_2D, GLES31.GL_TEXTURE_MAG_FILTER,
                GLES31.GL_LINEAR);
        GLES31.glTexParameteri(GLES31.GL_TEXTURE_2D, GLES31.GL_TEXTURE_WRAP_S,
                GLES31.GL_CLAMP_TO_EDGE);
        GLES31.glTexParameteri(GLES31.GL_TEXTURE_2D, GLES31.GL_TEXTURE_WRAP_T,
                GLES31.GL_CLAMP_TO_EDGE);
        GLES31.glTexImage2D(GLES31.GL_TEXTURE_2D, 0, GLES31.GL_RGBA, CACHE_WIDTH,
                CACHE_HEIGHT, 0, GLES31.GL_RGBA, GLES31.GL_UNSIGNED_BYTE, null);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, 0);
        return id;
    }
}
