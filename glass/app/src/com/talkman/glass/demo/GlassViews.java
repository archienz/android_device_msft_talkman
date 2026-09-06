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
import android.util.Log;
import android.view.View;

import com.talkman.glass.blur.TalkmanGlassCache;

import java.lang.reflect.Constructor;
import java.lang.reflect.Method;

/**
 * Instantiates {@code com.talkman.glass.core.TalkmanGlassView} when that class
 * is on the classpath. This module does not implement it.
 *
 * <p>Intended once {@code talkman-glass-core} ships:
 * <pre>
 *   TalkmanGlassView glass = new TalkmanGlassView(context);
 *   glass.setCache(cache);
 * </pre>
 * The view's GL thread must call {@link TalkmanGlassCache#create()} then
 * {@link TalkmanGlassCache#capture(Bitmap)} — those need a current GLES 3.1
 * context.
 */
final class GlassViews {
    static final String VIEW_CLASS = "com.talkman.glass.core.TalkmanGlassView";
    private static final String TAG = "TalkmanGlassDemo";

    private GlassViews() {}

    static View createPanel(Context context, TalkmanGlassCache cache, Bitmap wallpaper) {
        try {
            Class<?> clz = Class.forName(VIEW_CLASS);
            View view = instantiate(clz, context, cache);
            if (view == null) {
                return null;
            }
            bind(view, cache, wallpaper);
            return view;
        } catch (ClassNotFoundException e) {
            Log.i(TAG, VIEW_CLASS + " not on classpath yet");
            return null;
        } catch (Throwable t) {
            Log.w(TAG, "TalkmanGlassView bind failed", t);
            return null;
        }
    }

    private static View instantiate(Class<?> clz, Context context, TalkmanGlassCache cache)
            throws Exception {
        try {
            Constructor<?> ctor = clz.getConstructor(Context.class, TalkmanGlassCache.class);
            return (View) ctor.newInstance(context, cache);
        } catch (NoSuchMethodException ignored) {
        }
        Constructor<?> ctor = clz.getConstructor(Context.class);
        return (View) ctor.newInstance(context);
    }

    private static void bind(View view, TalkmanGlassCache cache, Bitmap wallpaper) {
        invoke1(view, "setCache", TalkmanGlassCache.class, cache);
        invoke1(view, "setGlassCache", TalkmanGlassCache.class, cache);
        invoke1(view, "bindCache", TalkmanGlassCache.class, cache);
        invoke1(view, "attachCache", TalkmanGlassCache.class, cache);
        invoke1(view, "setWallpaper", Bitmap.class, wallpaper);
        invoke1(view, "setSource", Bitmap.class, wallpaper);
        invoke1(view, "setSourceBitmap", Bitmap.class, wallpaper);
    }

    private static void invoke1(Object target, String name, Class<?> arg, Object value) {
        try {
            Method method = target.getClass().getMethod(name, arg);
            method.invoke(target, value);
        } catch (NoSuchMethodException ignored) {
        } catch (Throwable t) {
            Log.w(TAG, name + " failed", t);
        }
    }
}
