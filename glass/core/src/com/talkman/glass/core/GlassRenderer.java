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
import android.graphics.Color;
import android.opengl.GLES31;
import android.opengl.GLSurfaceView;

import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.opengles.GL10;

/**
 * One panel quad per frame. Frost lives in {@link DualKawaseBlur}; this class
 * only binds uTex and the look uniforms.
 */
final class GlassRenderer implements GLSurfaceView.Renderer {
    final Object lock = new Object();

    volatile float ior = 1.78f;
    volatile float dispersion = 1.35f;
    volatile float fresnel = 1.15f;
    volatile float warp = 1.35f;
    volatile float radiusPx = 18f;
    volatile float bevelPx = 28f;
    volatile float rectX;
    volatile float rectY;
    volatile float rectW = 1f;
    volatile float rectH = 1f;

    private final Context mAppContext;
    private final DualKawaseBlur mBlur = new DualKawaseBlur();
    private Bitmap mPending;
    private boolean mForceVoid;
    private static final float[] UNIT_QUAD = {
            0f, 0f,
            1f, 0f,
            0f, 1f,
            1f, 1f,
    };

    private int mProg;
    private int mVao;
    private int mVbo;
    private int mWidth = 1;
    private int mHeight = 1;
    private int mUTex;
    private int mUIor;
    private int mUDispersion;
    private int mUFresnel;
    private int mURadius;
    private int mUBevel;
    private int mUWarp;
    private int mUTime;
    private int mUResolution;
    private int mURect;
    private final long mEpochNs = System.nanoTime();

    GlassRenderer(Context context) {
        mAppContext = context.getApplicationContext();
    }

    void queueBackdrop(Bitmap bitmap) {
        synchronized (lock) {
            if (mPending != null && mPending != bitmap && !mPending.isRecycled()) {
                mPending.recycle();
            }
            mPending = bitmap;
        }
    }

    void queueVoidIfEmpty() {
        synchronized (lock) {
            mForceVoid = true;
        }
    }

    @Override
    public void onSurfaceCreated(GL10 unused, EGLConfig config) {
        mBlur.init(mAppContext);
        mProg = Glsl.link(
                Glsl.load(mAppContext, Glsl.GLASS_VERT),
                Glsl.load(mAppContext, Glsl.GLASS_FRAG),
                "glass");
        if (mProg != 0) {
            mUTex = GLES31.glGetUniformLocation(mProg, "uTex");
            mUIor = GLES31.glGetUniformLocation(mProg, "uIor");
            mUDispersion = GLES31.glGetUniformLocation(mProg, "uDispersion");
            mUFresnel = GLES31.glGetUniformLocation(mProg, "uFresnel");
            mURadius = GLES31.glGetUniformLocation(mProg, "uRadius");
            mUBevel = GLES31.glGetUniformLocation(mProg, "uBevel");
            mUWarp = GLES31.glGetUniformLocation(mProg, "uWarp");
            mUTime = GLES31.glGetUniformLocation(mProg, "uTime");
            mUResolution = GLES31.glGetUniformLocation(mProg, "uResolution");
            mURect = GLES31.glGetUniformLocation(mProg, "uRect");
        }
        mVao = 0;
        mVbo = 0;
        mVao = Glsl.createVao();
        mVbo = Glsl.createVbo(UNIT_QUAD);
        Glsl.bindUnitQuad(mVao, mVbo);
        GLES31.glBindBuffer(GLES31.GL_ARRAY_BUFFER, 0);
        GLES31.glBindVertexArray(0);
        GLES31.glClearColor(0f, 0f, 0f, 0f);
        GLES31.glDisable(GLES31.GL_DEPTH_TEST);
        GLES31.glDisable(GLES31.GL_CULL_FACE);
        GLES31.glEnable(GLES31.GL_BLEND);
        GLES31.glBlendFunc(GLES31.GL_SRC_ALPHA, GLES31.GL_ONE_MINUS_SRC_ALPHA);
        synchronized (lock) {
            mForceVoid = true;
        }
        Glsl.check("glass.surface");
    }

    @Override
    public void onSurfaceChanged(GL10 unused, int width, int height) {
        mWidth = Math.max(width, 1);
        mHeight = Math.max(height, 1);
        GLES31.glViewport(0, 0, mWidth, mHeight);
    }

    @Override
    public void onDrawFrame(GL10 unused) {
        Bitmap upload = null;
        boolean needVoid = false;
        synchronized (lock) {
            upload = mPending;
            mPending = null;
            needVoid = mForceVoid;
            mForceVoid = false;
        }
        if (upload != null) {
            mBlur.rebuild(upload);
            if (!upload.isRecycled()) {
                upload.recycle();
            }
        } else if (needVoid) {
            Bitmap voidBmp = Bitmap.createBitmap(DualKawaseBlur.CACHE_WIDTH,
                    DualKawaseBlur.CACHE_HEIGHT, Bitmap.Config.ARGB_8888);
            voidBmp.eraseColor(Color.BLACK);
            mBlur.rebuild(voidBmp);
            voidBmp.recycle();
        }

        GLES31.glViewport(0, 0, mWidth, mHeight);
        GLES31.glClear(GLES31.GL_COLOR_BUFFER_BIT);
        if (mProg == 0 || !mBlur.isReady()) {
            return;
        }

        GLES31.glUseProgram(mProg);
        GLES31.glActiveTexture(GLES31.GL_TEXTURE0);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, mBlur.resultTexture());
        GLES31.glUniform1i(mUTex, 0);
        GLES31.glUniform1f(mUIor, ior);
        GLES31.glUniform1f(mUDispersion, dispersion);
        GLES31.glUniform1f(mUFresnel, fresnel);
        GLES31.glUniform1f(mURadius, radiusPx);
        GLES31.glUniform1f(mUBevel, bevelPx);
        GLES31.glUniform1f(mUWarp, warp);
        GLES31.glUniform1f(mUTime, (System.nanoTime() - mEpochNs) * 1.0e-9f);
        GLES31.glUniform2f(mUResolution, mWidth, mHeight);
        GLES31.glUniform4f(mURect, rectX, rectY, rectW, rectH);
        Glsl.bindUnitQuad(mVao, mVbo);
        GLES31.glDrawArrays(GLES31.GL_TRIANGLE_STRIP, 0, 4);
        GLES31.glBindVertexArray(0);
        GLES31.glBindBuffer(GLES31.GL_ARRAY_BUFFER, 0);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, 0);
        GLES31.glUseProgram(0);
    }

    void destroyGl() {
        mBlur.release();
        Glsl.deleteProgram(mProg);
        mProg = 0;
        Glsl.deleteVao(mVao);
        mVao = 0;
        Glsl.deleteBuffer(mVbo);
        mVbo = 0;
        synchronized (lock) {
            if (mPending != null && !mPending.isRecycled()) {
                mPending.recycle();
            }
            mPending = null;
        }
    }
}
