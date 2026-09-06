/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.clock;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.widget.RemoteViews;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class ClockWidget extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        Date now = new Date();
        String time = new SimpleDateFormat("HH:mm", Locale.US).format(now);
        String date = new SimpleDateFormat("EEE dd MMM", Locale.US)
                .format(now).toUpperCase(Locale.US);
        Intent launch = new Intent(context, ClockActivity.class);
        PendingIntent pi = PendingIntent.getActivity(
                context, 0, launch, PendingIntent.FLAG_IMMUTABLE);
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(),
                    R.layout.widget_clock);
            views.setTextViewText(R.id.widget_time, time);
            views.setTextViewText(R.id.widget_date, date);
            views.setOnClickPendingIntent(R.id.widget_time, pi);
            manager.updateAppWidget(id, views);
        }
    }
}
