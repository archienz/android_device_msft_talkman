/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 */

package com.talkman.ui;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.util.AttributeSet;
import android.view.View;

import java.util.Random;

/** Void + sparse stars. Not a wallpaper capture. Adreno 418: draw cached dots. */
public class StarfieldView extends View {
    private static final int STAR_COUNT = 80;
    private final Paint mPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final float[] mX = new float[STAR_COUNT];
    private final float[] mY = new float[STAR_COUNT];
    private final float[] mR = new float[STAR_COUNT];
    private int mW;
    private int mH;

    public StarfieldView(Context context) {
        this(context, null);
    }

    public StarfieldView(Context context, AttributeSet attrs) {
        super(context, attrs);
        setWillNotDraw(false);
        mPaint.setColor(0x66E8E8E8);
        setBackgroundColor(0xFF000000);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);
        mW = w;
        mH = h;
        Random r = new Random(42);
        for (int i = 0; i < STAR_COUNT; i++) {
            mX[i] = r.nextFloat() * Math.max(w, 1);
            mY[i] = r.nextFloat() * Math.max(h, 1);
            mR[i] = 0.6f + r.nextFloat() * 1.4f;
        }
    }

    @Override
    protected void onDraw(Canvas canvas) {
        canvas.drawColor(0xFF000000);
        if (mW <= 0) {
            return;
        }
        for (int i = 0; i < STAR_COUNT; i++) {
            canvas.drawCircle(mX[i], mY[i], mR[i], mPaint);
        }
    }
}
