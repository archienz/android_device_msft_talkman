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

package com.talkman.glass.demo;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.RectF;
import android.graphics.drawable.Drawable;
import android.util.AttributeSet;
import android.view.View;

import com.talkman.glass.blur.TalkmanGlassCache;

import java.util.Random;

/**
 * Void wallpaper fallback: {@code #000000} + stars + a faint horizon arc.
 * Seed matches the generated wall note ({@code talkman-xphone-void-20260905}).
 */
public final class VoidStarView extends View {
    static final String SEED = "talkman-xphone-void-20260905";

    private final Paint mStar = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final Paint mArc = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF mArcBounds = new RectF();
    private Drawable mWallpaper;

    public VoidStarView(Context context) {
        super(context);
        init();
    }

    public VoidStarView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public VoidStarView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        mArc.setStyle(Paint.Style.STROKE);
        mArc.setColor(0x33E8E8E8);
        setWillNotDraw(false);
    }

    void setWallpaper(Drawable wallpaper) {
        mWallpaper = wallpaper;
        invalidate();
    }

    static Bitmap createCacheBitmap() {
        Bitmap bitmap = Bitmap.createBitmap(
                TalkmanGlassCache.WIDTH, TalkmanGlassCache.HEIGHT, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawVoid(canvas, bitmap.getWidth(), bitmap.getHeight(), new Paint(Paint.ANTI_ALIAS_FLAG),
                new Paint(Paint.ANTI_ALIAS_FLAG), new RectF());
        return bitmap;
    }

    static Bitmap drawableToCache(Drawable drawable) {
        if (drawable == null) {
            return createCacheBitmap();
        }
        Bitmap bitmap = Bitmap.createBitmap(
                TalkmanGlassCache.WIDTH, TalkmanGlassCache.HEIGHT, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        drawable.setBounds(0, 0, bitmap.getWidth(), bitmap.getHeight());
        drawable.draw(canvas);
        return bitmap;
    }

    @Override
    protected void onDraw(Canvas canvas) {
        int w = getWidth();
        int h = getHeight();
        if (mWallpaper != null) {
            mWallpaper.setBounds(0, 0, w, h);
            mWallpaper.draw(canvas);
            return;
        }
        drawVoid(canvas, w, h, mStar, mArc, mArcBounds);
    }

    static void drawVoid(Canvas canvas, int w, int h, Paint star, Paint arc, RectF arcBounds) {
        canvas.drawColor(Color.BLACK);
        if (w <= 0 || h <= 0) {
            return;
        }
        Random rng = new Random(SEED.hashCode());
        int count = Math.max(140, (w * h) / 4200);
        for (int i = 0; i < count; i++) {
            float x = rng.nextFloat() * w;
            float y = rng.nextFloat() * h;
            int a = 0x40 + rng.nextInt(0xA8);
            star.setColor(Color.argb(a, 0xE8, 0xE8, 0xE8));
            float r = rng.nextFloat() < 0.08f ? 1.6f : 0.7f;
            canvas.drawCircle(x, y, r, star);
        }
        arc.setStyle(Paint.Style.STROKE);
        arc.setStrokeWidth(Math.max(1.0f, h / 640.0f));
        arc.setColor(0x33E8E8E8);
        arcBounds.set(-w * 0.15f, h * 0.78f, w * 1.15f, h * 1.35f);
        canvas.drawArc(arcBounds, 200.0f, 140.0f, false, arc);
        Paint grid = star;
        grid.setStyle(Paint.Style.STROKE);
        grid.setStrokeWidth(Math.max(1.0f, w / 720.0f));
        grid.setColor(0x66E8E8E8);
        int gx = Math.max(24, w / 10);
        int gy = Math.max(24, h / 16);
        for (int x = 0; x <= w; x += gx) {
            canvas.drawLine(x, 0, x, h, grid);
        }
        for (int y = 0; y <= h; y += gy) {
            canvas.drawLine(0, y, w, y, grid);
        }
        grid.setStyle(Paint.Style.STROKE);
        grid.setStrokeWidth(Math.max(1.5f, w / 480.0f));
        grid.setColor(0x99E8E8E8);
        canvas.drawCircle(w * 0.28f, h * 0.22f, Math.min(w, h) * 0.11f, grid);
        canvas.drawCircle(w * 0.72f, h * 0.18f, Math.min(w, h) * 0.07f, grid);
    }
}
