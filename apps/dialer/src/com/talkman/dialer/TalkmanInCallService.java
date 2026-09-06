/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.dialer;

import android.content.Intent;
import android.telecom.Call;
import android.telecom.InCallService;

public class TalkmanInCallService extends InCallService {
    static TalkmanInCallService instance;

    @Override
    public void onCreate() {
        super.onCreate();
        instance = this;
    }

    @Override
    public void onDestroy() {
        if (instance == this) {
            instance = null;
        }
        super.onDestroy();
    }

    @Override
    public void onCallAdded(Call call) {
        Intent i = new Intent(this, InCallActivity.class);
        i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(i);
    }

    @Override
    public void onCallRemoved(Call call) {
        if (getCalls() == null || getCalls().isEmpty()) {
            InCallActivity.finishIfOpen();
        }
    }
}
