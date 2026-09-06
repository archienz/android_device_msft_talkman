/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.widgets;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.widget.RemoteViews;

public class DockWidget extends AppWidgetProvider {
    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] ids) {
        for (int id : ids) {
            RemoteViews views = new RemoteViews(context.getPackageName(),
                    R.layout.widget_dock);
            views.setOnClickPendingIntent(R.id.dock_phone,
                    launch(context, 1, "com.talkman.dialer",
                            "com.talkman.dialer.DialerActivity"));
            views.setOnClickPendingIntent(R.id.dock_messages,
                    launch(context, 2, "com.talkman.messages",
                            "com.talkman.messages.InboxActivity"));
            views.setOnClickPendingIntent(R.id.dock_browser,
                    action(context, 3, Intent.ACTION_VIEW,
                            android.net.Uri.parse("https://")));
            views.setOnClickPendingIntent(R.id.dock_camera,
                    action(context, 4, android.provider.MediaStore.INTENT_ACTION_STILL_IMAGE_CAMERA,
                            null));
            manager.updateAppWidget(id, views);
        }
    }

    private static PendingIntent launch(Context ctx, int req, String pkg, String cls) {
        Intent i = new Intent();
        i.setComponent(new ComponentName(pkg, cls));
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return PendingIntent.getActivity(ctx, req, i, PendingIntent.FLAG_IMMUTABLE);
    }

    private static PendingIntent action(Context ctx, int req, String action,
            android.net.Uri data) {
        Intent i = new Intent(action, data);
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return PendingIntent.getActivity(ctx, req, i, PendingIntent.FLAG_IMMUTABLE);
    }
}
