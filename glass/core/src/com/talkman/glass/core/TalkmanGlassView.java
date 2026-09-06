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
import android.graphics.PixelFormat;
import android.opengl.GLSurfaceView;
import android.util.AttributeSet;
import android.util.DisplayMetrics;

import javax.microedition.khronos.egl.EGL10;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.egl.EGLContext;
import javax.microedition.khronos.egl.EGLDisplay;

/**
 * GLES 3.1 liquid-glass panel for talkman (Adreno 418).
 *
 * <p>Host Activity attach:
 * <pre>
 *   public class HostActivity extends Activity {
 *       private TalkmanGlassView mGlass;
 *
 *       protected void onCreate(Bundle saved) {
 *           super.onCreate(saved);
 *           mGlass = new TalkmanGlassView(this);
 *           mGlass.setOverlayCompositing(true);
 *           setContentView(mGlass);
 *           mGlass.setWallpaper(wallpaperBitmap);
 *           mGlass.setRect(0.06f, 0.12f, 0.88f, 0.36f);
 *       }
 *
 *       protected void onResume() {
 *           super.onResume();
 *           mGlass.onResume();
 *       }
 *
 *       protected void onPause() {
 *           mGlass.onPause();
 *           super.onPause();
 *       }
 *   }
 * </pre>
 *
 * <p>Soong: {@code static_libs: ["libtalkman-glass"]}. Call
 * {@link #onResume()} / {@link #onPause()}. Feed wallpaper or a shade snap
 * via {@link #setWallpaper} / {@link #setBackdrop}; this view never captures
 * the 1440x2560 framebuffer. While the shade drags, keep calling
 * {@link #setBackdrop}; {@link #notifyShadeSettled()} freezes new snaps after
 * 250 ms.
 */
public class TalkmanGlassView extends GLSurfaceView {
    public static final int CACHE_WIDTH = DualKawaseBlur.CACHE_WIDTH;
    public static final int CACHE_HEIGHT = DualKawaseBlur.CACHE_HEIGHT;
    public static final long SETTLE_FREEZE_MS = 250L;

    private static final int EGL_CONTEXT_CLIENT_VERSION = 0x3098;
    private static final int EGL_CONTEXT_MINOR_VERSION = 0x30FB;

    private final GlassRenderer mRenderer;
    private boolean mDragging;
    private boolean mFrozen;
    private final Runnable mFreezeRunnable = new Runnable() {
        @Override
        public void run() {
            mFrozen = true;
            setRenderMode(RENDERMODE_WHEN_DIRTY);
            requestRender();
        }
    };

    public TalkmanGlassView(Context context) {
        this(context, null);
    }

    public TalkmanGlassView(Context context, AttributeSet attrs) {
        super(context, attrs);
        setEGLContextClientVersion(3);
        setEGLContextFactory(new Es31ContextFactory());
        setEGLConfigChooser(8, 8, 8, 8, 0, 0);
        getHolder().setFormat(PixelFormat.TRANSLUCENT);
        setPreserveEGLContextOnPause(true);
        mRenderer = new GlassRenderer(context);
        DisplayMetrics dm = context.getResources().getDisplayMetrics();
        mRenderer.radiusPx = 6f * dm.density;
        mRenderer.bevelPx = 28f * dm.density;
        setRenderer(mRenderer);
        // Liquid flow needs time. Shade hosts may switch to WHEN_DIRTY after settle.
        setRenderMode(RENDERMODE_CONTINUOUSLY);
    }

    /**
     * Call before the surface exists. Enables 8-bit alpha; optional
     * {@link #setZOrderOnTop(boolean)} so a translucent Activity can show
     * through outside {@code uRect}.
     */
    public void setOverlayCompositing(boolean zOrderOnTop) {
        getHolder().setFormat(PixelFormat.TRANSLUCENT);
        if (zOrderOnTop) {
            setZOrderOnTop(true);
        }
    }

    public void setIor(float ior) {
        mRenderer.ior = Math.max(ior, 1.001f);
        requestRender();
    }

    public void setDispersion(float dispersion) {
        mRenderer.dispersion = Math.max(dispersion, 0f);
        requestRender();
    }

    public void setFresnel(float fresnel) {
        mRenderer.fresnel = Math.max(fresnel, 0f);
        requestRender();
    }

    /** Corner radius in view pixels (tight 4-6 dp on talkman). */
    public void setRadius(float radiusPx) {
        mRenderer.radiusPx = Math.max(radiusPx, 0f);
        requestRender();
    }

    /** Bevel width in view pixels. */
    public void setBevel(float bevelPx) {
        mRenderer.bevelPx = Math.max(bevelPx, 1f);
        requestRender();
    }

    /** Displacement magnitude. 1 = demo default; GlassiFy-class warp is ~1.2–1.6. */
    public void setWarp(float warp) {
        mRenderer.warp = Math.max(warp, 0f);
        requestRender();
    }

    /**
     * Panel in view-normalized coordinates, Android y-down.
     * {@code (x, y, w, h)} each in 0..1.
     */
    public void setRect(float x, float y, float w, float h) {
        mRenderer.rectX = clamp01(x);
        mRenderer.rectY = clamp01(y);
        mRenderer.rectW = Math.max(w, 0.01f);
        mRenderer.rectH = Math.max(h, 0.01f);
        requestRender();
    }

    /**
     * Wallpaper or last shade snap. Scaled to 360x640 and Dual-Kawase rebuilt.
     * Ignored while the settle freeze is active (use {@link #setWallpaper}
     * or {@link #invalidateCache()} to break the freeze).
     */
    public void setBackdrop(Bitmap bitmap) {
        if (bitmap == null || bitmap.isRecycled()) {
            return;
        }
        if (mFrozen && !mDragging) {
            return;
        }
        enqueueScaled(bitmap);
    }

    /** Always rebuilds the frost cache (wallpaper change). */
    public void setWallpaper(Bitmap bitmap) {
        mFrozen = false;
        removeCallbacks(mFreezeRunnable);
        if (bitmap == null || bitmap.isRecycled()) {
            mRenderer.queueVoidIfEmpty();
            requestRender();
            return;
        }
        enqueueScaled(bitmap);
    }

    public void invalidateCache() {
        mFrozen = false;
        removeCallbacks(mFreezeRunnable);
    }

    /**
     * While {@code true}, new {@link #setBackdrop} calls apply immediately and
     * the view draws continuously. {@code false} starts the 250 ms freeze.
     */
    public void setShadeDragging(boolean dragging) {
        mDragging = dragging;
        if (dragging) {
            mFrozen = false;
            removeCallbacks(mFreezeRunnable);
            setRenderMode(RENDERMODE_CONTINUOUSLY);
        } else {
            notifyShadeSettled();
        }
    }

    /** Last snap may still be applied; 250 ms later the cache freezes. */
    public void notifyShadeSettled() {
        mDragging = false;
        removeCallbacks(mFreezeRunnable);
        postDelayed(mFreezeRunnable, SETTLE_FREEZE_MS);
    }

    @Override
    protected void onDetachedFromWindow() {
        removeCallbacks(mFreezeRunnable);
        super.onDetachedFromWindow();
    }

    private void enqueueScaled(Bitmap bitmap) {
        Bitmap scaled;
        try {
            if (bitmap.getWidth() == CACHE_WIDTH && bitmap.getHeight() == CACHE_HEIGHT
                    && bitmap.getConfig() == Bitmap.Config.ARGB_8888) {
                scaled = bitmap.copy(Bitmap.Config.ARGB_8888, false);
            } else {
                Bitmap tmp = Bitmap.createScaledBitmap(bitmap, CACHE_WIDTH, CACHE_HEIGHT, true);
                if (tmp.getConfig() == Bitmap.Config.ARGB_8888 && tmp != bitmap) {
                    scaled = tmp;
                } else {
                    scaled = tmp.copy(Bitmap.Config.ARGB_8888, false);
                    if (tmp != bitmap && tmp != scaled) {
                        tmp.recycle();
                    }
                }
            }
        } catch (RuntimeException e) {
            return;
        }
        if (scaled == null) {
            return;
        }
        mRenderer.queueBackdrop(scaled);
        requestRender();
    }

    private static float clamp01(float v) {
        if (v < 0f) {
            return 0f;
        }
        if (v > 1f) {
            return 1f;
        }
        return v;
    }

    static final class Es31ContextFactory implements EGLContextFactory {
        @Override
        public EGLContext createContext(EGL10 egl, EGLDisplay display, EGLConfig eglConfig) {
            int[] es31 = {
                    EGL_CONTEXT_CLIENT_VERSION, 3,
                    EGL_CONTEXT_MINOR_VERSION, 1,
                    EGL10.EGL_NONE
            };
            EGLContext ctx = egl.eglCreateContext(display, eglConfig, EGL10.EGL_NO_CONTEXT, es31);
            if (ctx != null && ctx != EGL10.EGL_NO_CONTEXT) {
                return ctx;
            }
            int[] es30 = {EGL_CONTEXT_CLIENT_VERSION, 3, EGL10.EGL_NONE};
            return egl.eglCreateContext(display, eglConfig, EGL10.EGL_NO_CONTEXT, es30);
        }

        @Override
        public void destroyContext(EGL10 egl, EGLDisplay display, EGLContext context) {
            egl.eglDestroyContext(display, context);
        }
    }
}
