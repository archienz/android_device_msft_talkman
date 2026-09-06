/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.ui;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;
import android.graphics.RectF;
import android.util.AttributeSet;
import android.view.View;

/** Thin planetary arc. Hairline ink, no bitmap wallpaper capture. */
public class HorizonView extends View {
    private final Paint mPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private final RectF mOval = new RectF();

    public HorizonView(Context context) {
        this(context, null);
    }

    public HorizonView(Context context, AttributeSet attrs) {
        super(context, attrs);
        mPaint.setStyle(Paint.Style.STROKE);
        mPaint.setColor(0xE8E8E8E8);
        mPaint.setStrokeWidth(getResources().getDisplayMetrics().density * 1.25f);
        setBackgroundColor(0x00000000);
    }

    @Override
    protected void onDraw(Canvas canvas) {
        float w = getWidth();
        float h = getHeight();
        if (w <= 0 || h <= 0) {
            return;
        }
        float radius = w * 1.15f;
        mOval.set(w / 2f - radius, h * 0.08f, w / 2f + radius, h * 0.08f + 2f * radius);
        canvas.drawArc(mOval, 200f, 140f, false, mPaint);
    }
}
