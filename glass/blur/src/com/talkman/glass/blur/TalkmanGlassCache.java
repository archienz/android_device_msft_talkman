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

import android.graphics.Bitmap;
import android.opengl.EGL14;
import android.opengl.GLES31;
import android.opengl.GLUtils;
import android.os.SystemClock;
import android.util.Log;

import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.FloatBuffer;

/**
 * Frosted-glass background cache for Talkman (Lumia 950 / Adreno 418).
 *
 * <p>Never blurs a 1440×2560 framebuffer. Callers pass a wallpaper or shade
 * snapshot {@link Bitmap}; it is downsampled on the CPU to {@link #WIDTH}×
 * {@link #HEIGHT}, then dual-Kawase is run as exactly {@link #PASSES} GLES 3.1
 * draws through one FBO ping-pong (180×320 → 90×160 → 360×640).
 *
 * <p>GL methods require a current GLES 3.1 context (the
 * {@code GLSurfaceView}/{@code TextureView} renderer thread in
 * {@code com.talkman.glass}). Invalidate methods are thread-safe.
 *
 * <p>{@link #getTextureId()} is a {@code GL_TEXTURE_2D} (RGBA8, linear,
 * clamp). V=0 is the GL bottom after the first-pass Y flip.
 */
public final class TalkmanGlassCache {
    public static final int WIDTH = 360;
    public static final int HEIGHT = 640;
    public static final int PASSES = 3;
    public static final long FREEZE_AFTER_DRAG_MS = 250L;

    static final int PING_WIDTH = 180;
    static final int PING_HEIGHT = 320;
    static final int PONG_WIDTH = 90;
    static final int PONG_HEIGHT = 160;

    private static final String TAG = "TalkmanGlassCache";
    private static final float OFFSET = 1.0f;

    private static final float[] FULLSCREEN_TRI = {
            -1.0f, -1.0f,
             3.0f, -1.0f,
            -1.0f,  3.0f,
    };

    private int mProgDown;
    private int mProgUp;
    private int mDownTex;
    private int mDownHalf;
    private int mDownFlip;
    private int mUpTex;
    private int mUpHalf;

    private int mFbo;
    private int mVao;
    private int mVbo;
    private int mTexOut;
    private int mTexPing;
    private int mTexPong;

    private boolean mCreated;
    private boolean mHasContent;

    private volatile boolean mDirty = true;
    private volatile long mFrozenUntilMs;

    /** Allocate programs, one FBO, and ping-pong textures. GL thread. */
    public void create() {
        if (mCreated) {
            return;
        }
        if (!hasCurrentContext()) {
            Log.e(TAG, "create() needs a current GLES context");
            return;
        }

        mProgDown = GlUtil.linkProgram(KawaseShaders.VERT, KawaseShaders.FRAG_DOWN);
        mProgUp = GlUtil.linkProgram(KawaseShaders.VERT, KawaseShaders.FRAG_UP);
        if (mProgDown == 0 || mProgUp == 0) {
            destroy();
            return;
        }
        mDownTex = GLES31.glGetUniformLocation(mProgDown, "uTex");
        mDownHalf = GLES31.glGetUniformLocation(mProgDown, "uHalfPixel");
        mDownFlip = GLES31.glGetUniformLocation(mProgDown, "uFlipY");
        mUpTex = GLES31.glGetUniformLocation(mProgUp, "uTex");
        mUpHalf = GLES31.glGetUniformLocation(mProgUp, "uHalfPixel");

        mTexOut = GlUtil.createRgbaTexture(WIDTH, HEIGHT);
        mTexPing = GlUtil.createRgbaTexture(PING_WIDTH, PING_HEIGHT);
        mTexPong = GlUtil.createRgbaTexture(PONG_WIDTH, PONG_HEIGHT);

        int[] ids = new int[1];
        GLES31.glGenFramebuffers(1, ids, 0);
        mFbo = ids[0];

        GLES31.glGenVertexArrays(1, ids, 0);
        mVao = ids[0];
        GLES31.glGenBuffers(1, ids, 0);
        mVbo = ids[0];

        FloatBuffer verts = ByteBuffer.allocateDirect(FULLSCREEN_TRI.length * 4)
                .order(ByteOrder.nativeOrder())
                .asFloatBuffer();
        verts.put(FULLSCREEN_TRI).position(0);

        GLES31.glBindVertexArray(mVao);
        GLES31.glBindBuffer(GLES31.GL_ARRAY_BUFFER, mVbo);
        GLES31.glBufferData(GLES31.GL_ARRAY_BUFFER, FULLSCREEN_TRI.length * 4, verts,
                GLES31.GL_STATIC_DRAW);
        GLES31.glEnableVertexAttribArray(0);
        GLES31.glVertexAttribPointer(0, 2, GLES31.GL_FLOAT, false, 8, 0);
        GLES31.glBindVertexArray(0);
        GLES31.glBindBuffer(GLES31.GL_ARRAY_BUFFER, 0);

        mCreated = true;
        mHasContent = false;
    }

    /** Delete GL objects. GL thread. */
    public void destroy() {
        if (!hasCurrentContext()) {
            mCreated = false;
            mHasContent = false;
            mTexOut = 0;
            return;
        }
        if (mFbo != 0) {
            GLES31.glDeleteFramebuffers(1, new int[] {mFbo}, 0);
            mFbo = 0;
        }
        if (mVao != 0) {
            GLES31.glDeleteVertexArrays(1, new int[] {mVao}, 0);
            mVao = 0;
        }
        if (mVbo != 0) {
            GLES31.glDeleteBuffers(1, new int[] {mVbo}, 0);
            mVbo = 0;
        }
        if (mProgDown != 0) {
            GLES31.glDeleteProgram(mProgDown);
            mProgDown = 0;
        }
        if (mProgUp != 0) {
            GLES31.glDeleteProgram(mProgUp);
            mProgUp = 0;
        }
        GlUtil.deleteTexture(mTexOut);
        GlUtil.deleteTexture(mTexPing);
        GlUtil.deleteTexture(mTexPong);
        mTexOut = 0;
        mTexPing = 0;
        mTexPong = 0;
        mCreated = false;
        mHasContent = false;
    }

    /**
     * Downsample {@code source} to 360×640 and run {@link #PASSES} dual-Kawase
     * draws. No-op while {@link #isFrozen()} (250 ms after shade settle).
     * Wallpaper rebuilds should call {@link #invalidateWallpaper()} first.
     */
    public void capture(Bitmap source) {
        capture(source, false);
    }

    /**
     * Same as {@link #capture(Bitmap)}; {@code force} rebuilds even while the
     * post-drag freeze is active.
     */
    public void capture(Bitmap source, boolean force) {
        if (source == null || source.isRecycled()) {
            return;
        }
        if (!force && isFrozen()) {
            return;
        }
        if (!mCreated) {
            create();
        }
        if (!mCreated) {
            return;
        }
        Bitmap scaled = downsample(source);
        boolean recycle = scaled != source;
        try {
            kawase3(scaled);
            mHasContent = true;
            mDirty = false;
        } finally {
            if (recycle) {
                scaled.recycle();
            }
        }
    }

    /** Blurred cache {@code GL_TEXTURE_2D} id, or 0 if not created. */
    public int getTextureId() {
        return mHasContent ? mTexOut : 0;
    }

    /** Bind the cache to {@code GL_TEXTUREi}. GL thread. */
    public void bind(int unit) {
        GLES31.glActiveTexture(GLES31.GL_TEXTURE0 + unit);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, getTextureId());
    }

    public int getWidth() {
        return WIDTH;
    }

    public int getHeight() {
        return HEIGHT;
    }

    public int getPassCount() {
        return PASSES;
    }

    public boolean isReady() {
        return mHasContent && mTexOut != 0;
    }

    /**
     * Wallpaper changed. Clears any drag freeze so the next
     * {@link #capture(Bitmap)} rebuilds immediately.
     */
    public void invalidateWallpaper() {
        mFrozenUntilMs = 0L;
        mDirty = true;
    }

    /** Same as {@link #invalidateWallpaper()}. */
    public void invalidate() {
        invalidateWallpaper();
    }

    /** Shade drag started — allow recapture; do not sample every frame. */
    public void onDragStart() {
        mFrozenUntilMs = 0L;
        mDirty = true;
    }

    /** Shade settled — ignore {@link #capture(Bitmap)} for 250 ms. */
    public void freezeAfterDrag() {
        mFrozenUntilMs = SystemClock.elapsedRealtime() + FREEZE_AFTER_DRAG_MS;
    }

    /** Same as {@link #freezeAfterDrag()}. */
    public void onDragEnd() {
        freezeAfterDrag();
    }

    public boolean isFrozen() {
        return SystemClock.elapsedRealtime() < mFrozenUntilMs;
    }

    /** True when a new bitmap should be captured (dirty and not frozen). */
    public boolean needsCapture() {
        return mDirty && !isFrozen();
    }

    private static boolean hasCurrentContext() {
        return EGL14.eglGetCurrentContext() != null
                && EGL14.eglGetCurrentContext() != EGL14.EGL_NO_CONTEXT;
    }

    private static Bitmap downsample(Bitmap source) {
        if (source.getWidth() == WIDTH && source.getHeight() == HEIGHT
                && source.getConfig() == Bitmap.Config.ARGB_8888) {
            return source;
        }
        Bitmap scaled = Bitmap.createScaledBitmap(source, WIDTH, HEIGHT, true);
        if (scaled.getConfig() == Bitmap.Config.ARGB_8888) {
            return scaled;
        }
        Bitmap conv = scaled.copy(Bitmap.Config.ARGB_8888, false);
        if (scaled != source) {
            scaled.recycle();
        }
        return conv;
    }

    /**
     * Pass 1 down 360×640 → 180×320, pass 2 down 180×320 → 90×160,
     * pass 3 up 90×160 → 360×640. One FBO, attachments swapped.
     */
    private void kawase3(Bitmap bitmap) {
        int[] prevFbo = new int[1];
        int[] prevViewport = new int[4];
        GLES31.glGetIntegerv(GLES31.GL_FRAMEBUFFER_BINDING, prevFbo, 0);
        GLES31.glGetIntegerv(GLES31.GL_VIEWPORT, prevViewport, 0);

        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, mTexOut);
        GLUtils.texSubImage2D(GLES31.GL_TEXTURE_2D, 0, 0, 0, bitmap);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, 0);

        GLES31.glDisable(GLES31.GL_BLEND);
        GLES31.glDisable(GLES31.GL_DEPTH_TEST);
        GLES31.glDisable(GLES31.GL_CULL_FACE);
        GLES31.glColorMask(true, true, true, true);
        GLES31.glBindVertexArray(mVao);

        // Pass 1: downsample + Android→GL Y flip. halfpixel vs dest size.
        drawDown(mTexOut, mTexPing, PING_WIDTH, PING_HEIGHT, OFFSET, 1.0f);
        // Pass 2: downsample again.
        drawDown(mTexPing, mTexPong, PONG_WIDTH, PONG_HEIGHT, OFFSET, 0.0f);
        // Pass 3: upsample back to the cache resolution. halfpixel vs src size.
        drawUp(mTexPong, mTexOut, WIDTH, HEIGHT, PONG_WIDTH, PONG_HEIGHT, OFFSET);

        // Detach so Adreno can sample mTexOut from the default framebuffer.
        GLES31.glFramebufferTexture2D(GLES31.GL_FRAMEBUFFER,
                GLES31.GL_COLOR_ATTACHMENT0, GLES31.GL_TEXTURE_2D, 0, 0);

        GLES31.glBindVertexArray(0);
        GLES31.glUseProgram(0);
        GLES31.glBindFramebuffer(GLES31.GL_FRAMEBUFFER, prevFbo[0]);
        GLES31.glViewport(prevViewport[0], prevViewport[1],
                prevViewport[2], prevViewport[3]);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, 0);
    }

    private void drawDown(int src, int dest, int destW, int destH,
            float offset, float flipY) {
        bindDest(dest, destW, destH);
        GLES31.glUseProgram(mProgDown);
        GLES31.glActiveTexture(GLES31.GL_TEXTURE0);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, src);
        GLES31.glUniform1i(mDownTex, 0);
        GLES31.glUniform2f(mDownHalf, 0.5f * offset / destW, 0.5f * offset / destH);
        GLES31.glUniform1f(mDownFlip, flipY);
        GLES31.glDrawArrays(GLES31.GL_TRIANGLES, 0, 3);
    }

    private void drawUp(int src, int dest, int destW, int destH,
            int srcW, int srcH, float offset) {
        bindDest(dest, destW, destH);
        GLES31.glUseProgram(mProgUp);
        GLES31.glActiveTexture(GLES31.GL_TEXTURE0);
        GLES31.glBindTexture(GLES31.GL_TEXTURE_2D, src);
        GLES31.glUniform1i(mUpTex, 0);
        GLES31.glUniform2f(mUpHalf, 0.5f * offset / srcW, 0.5f * offset / srcH);
        GLES31.glDrawArrays(GLES31.GL_TRIANGLES, 0, 3);
    }

    private void bindDest(int destTex, int destW, int destH) {
        GLES31.glBindFramebuffer(GLES31.GL_FRAMEBUFFER, mFbo);
        GLES31.glFramebufferTexture2D(GLES31.GL_FRAMEBUFFER,
                GLES31.GL_COLOR_ATTACHMENT0, GLES31.GL_TEXTURE_2D, 0, 0);
        GLES31.glFramebufferTexture2D(GLES31.GL_FRAMEBUFFER,
                GLES31.GL_COLOR_ATTACHMENT0, GLES31.GL_TEXTURE_2D, destTex, 0);
        GlUtil.framebufferComplete();
        GLES31.glViewport(0, 0, destW, destH);
    }
}
