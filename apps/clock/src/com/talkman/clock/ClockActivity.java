/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.clock;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Bundle;
import android.widget.TextView;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class ClockActivity extends Activity {
    private TextView mTime;
    private TextView mDate;
    private final SimpleDateFormat mTimeFmt =
            new SimpleDateFormat("HH:mm", Locale.US);
    private final SimpleDateFormat mDateFmt =
            new SimpleDateFormat("EEE dd MMM", Locale.US);
    private final BroadcastReceiver mTick = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            bind();
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_clock);
        mTime = findViewById(R.id.clock_time);
        mDate = findViewById(R.id.clock_date);
    }

    @Override
    protected void onResume() {
        super.onResume();
        registerReceiver(mTick, new IntentFilter(Intent.ACTION_TIME_TICK));
        bind();
    }

    @Override
    protected void onPause() {
        try {
            unregisterReceiver(mTick);
        } catch (IllegalArgumentException ignored) {
        }
        super.onPause();
    }

    private void bind() {
        Date now = new Date();
        mTime.setText(mTimeFmt.format(now));
        mDate.setText(mDateFmt.format(now).toUpperCase(Locale.US));
    }
}
