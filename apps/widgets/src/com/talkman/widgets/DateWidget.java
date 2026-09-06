/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.widgets;

import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.widget.RemoteViews;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class DateWidget extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        String date = new SimpleDateFormat("EEE dd MMM", Locale.US)
                .format(new Date()).toUpperCase(Locale.US);
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(),
                    R.layout.widget_date);
            views.setTextViewText(R.id.date_text, date);
            manager.updateAppWidget(id, views);
        }
    }
}
