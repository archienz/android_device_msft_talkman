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

import android.app.Activity;
import android.app.WallpaperManager;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.TextView;

import com.talkman.glass.core.TalkmanGlassView;

/**
 * Void (or black + stars) with a QS-sized glass panel.
 *
 * <p>{@link TalkmanGlassView} ({@code libtalkman-glass}) owns Dual-Kawase.
 * Wallpaper is downsampled to 360×640 inside the view — never 1440×2560 blur.
 */
public class GlassDemoActivity extends Activity {
    private TalkmanGlassView mGlass;
    private Bitmap mCacheBmp;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_glass_demo);

        VoidStarView voidLayer = findViewById(R.id.void_layer);
        // Same grid the lens samples. A flat wallpaper hides the bend.
        voidLayer.setWallpaper(null);
        mCacheBmp = VoidStarView.createCacheBitmap();

        FrameLayout slot = findViewById(R.id.qs_glass_slot);
        View stub = findViewById(R.id.qs_glass_stub);
        TextView status = findViewById(R.id.glass_status);

        mGlass = new TalkmanGlassView(this);
        mGlass.setOverlayCompositing(false);
        mGlass.setRect(0f, 0f, 1f, 1f);
        mGlass.setIor(1.82f);
        mGlass.setDispersion(1.45f);
        mGlass.setFresnel(1.2f);
        mGlass.setWarp(1.45f);
        float d = getResources().getDisplayMetrics().density;
        mGlass.setBevel(32f * d);
        mGlass.setWallpaper(mCacheBmp);
        slot.addView(mGlass, 0, new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT));
        stub.setVisibility(View.GONE);
        status.setText(R.string.glass_live);
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mGlass != null) {
            mGlass.onResume();
        }
    }

    @Override
    protected void onPause() {
        if (mGlass != null) {
            mGlass.onPause();
        }
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        if (mCacheBmp != null && !mCacheBmp.isRecycled()) {
            mCacheBmp.recycle();
            mCacheBmp = null;
        }
        super.onDestroy();
    }

    private Drawable loadWallpaper() {
        try {
            return WallpaperManager.getInstance(this).getDrawable();
        } catch (Throwable ignored) {
            return null;
        }
    }
}
