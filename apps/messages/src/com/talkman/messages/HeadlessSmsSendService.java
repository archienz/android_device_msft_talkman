/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.messages;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.telephony.SmsManager;
import android.text.TextUtils;

public class HeadlessSmsSendService extends Service {
    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && intent.getData() != null) {
            String addr = intent.getData().getSchemeSpecificPart();
            CharSequence text = intent.getCharSequenceExtra(Intent.EXTRA_TEXT);
            if (!TextUtils.isEmpty(addr) && text != null) {
                SmsManager.getDefault().sendTextMessage(addr, null, text.toString(),
                        null, null);
            }
        }
        stopSelf(startId);
        return START_NOT_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
