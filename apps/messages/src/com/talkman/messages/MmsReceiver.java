/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.messages;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** Required default-SMS stub. MMS body is not decoded here. */
public class MmsReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
    }
}
