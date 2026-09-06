/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.messages;

import android.content.BroadcastReceiver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.provider.Telephony;
import android.telephony.SmsMessage;

/** Default-SMS deliver receiver. Writes inbox so Telephony stays consistent. */
public class SmsReceiver extends BroadcastReceiver {
    @Override
    public void onReceive(Context context, Intent intent) {
        if (!Telephony.Sms.Intents.SMS_DELIVER_ACTION.equals(intent.getAction())) {
            return;
        }
        SmsMessage[] msgs = Telephony.Sms.Intents.getMessagesFromIntent(intent);
        if (msgs == null) {
            return;
        }
        for (SmsMessage msg : msgs) {
            if (msg == null) {
                continue;
            }
            ContentValues v = new ContentValues();
            v.put(Telephony.Sms.ADDRESS, msg.getDisplayOriginatingAddress());
            v.put(Telephony.Sms.BODY, msg.getMessageBody());
            v.put(Telephony.Sms.DATE, System.currentTimeMillis());
            v.put(Telephony.Sms.READ, 0);
            v.put(Telephony.Sms.TYPE, Telephony.Sms.MESSAGE_TYPE_INBOX);
            context.getContentResolver().insert(Telephony.Sms.Inbox.CONTENT_URI, v);
        }
    }
}
