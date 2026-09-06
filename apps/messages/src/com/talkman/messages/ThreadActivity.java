/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.messages;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.os.Bundle;
import android.provider.Telephony;
import android.telephony.SmsManager;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.widget.BaseAdapter;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import java.util.ArrayList;
import java.util.List;

public class ThreadActivity extends Activity {
    public static final String EXTRA_ADDRESS = "address";

    private String mAddress;
    private final List<Msg> mRows = new ArrayList<Msg>();
    private RowAdapter mAdapter;
    private EditText mBody;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mAddress = getIntent().getStringExtra(EXTRA_ADDRESS);
        setContentView(R.layout.activity_thread);
        ((TextView) findViewById(R.id.thread_title)).setText(mAddress);
        mBody = findViewById(R.id.body);
        ListView list = findViewById(R.id.list);
        mAdapter = new RowAdapter();
        list.setAdapter(mAdapter);
        findViewById(R.id.btn_send).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                send();
            }
        });
        load();
    }

    private void send() {
        String text = mBody.getText().toString();
        if (TextUtils.isEmpty(text) || TextUtils.isEmpty(mAddress)) {
            return;
        }
        if (checkSelfPermission(Manifest.permission.SEND_SMS)
                != PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(this, R.string.need_sms, Toast.LENGTH_SHORT).show();
            return;
        }
        SmsManager.getDefault().sendTextMessage(mAddress, null, text, null, null);
        mBody.setText("");
        load();
    }

    private void load() {
        mRows.clear();
        if (checkSelfPermission(Manifest.permission.READ_SMS)
                != PackageManager.PERMISSION_GRANTED) {
            mAdapter.notifyDataSetChanged();
            return;
        }
        Cursor c = getContentResolver().query(Telephony.Sms.CONTENT_URI,
                new String[]{Telephony.Sms.BODY, Telephony.Sms.TYPE, Telephony.Sms.DATE},
                Telephony.Sms.ADDRESS + "=?",
                new String[]{mAddress},
                Telephony.Sms.DATE + " ASC");
        if (c == null) {
            return;
        }
        try {
            while (c.moveToNext()) {
                Msg m = new Msg();
                m.body = c.getString(0);
                m.out = c.getInt(1) == Telephony.Sms.MESSAGE_TYPE_SENT
                        || c.getInt(1) == Telephony.Sms.MESSAGE_TYPE_OUTBOX;
                mRows.add(m);
            }
        } finally {
            c.close();
        }
        mAdapter.notifyDataSetChanged();
    }

    private static final class Msg {
        String body;
        boolean out;
    }

    private final class RowAdapter extends BaseAdapter {
        @Override
        public int getCount() {
            return mRows.size();
        }

        @Override
        public Object getItem(int position) {
            return mRows.get(position);
        }

        @Override
        public long getItemId(int position) {
            return position;
        }

        @Override
        public View getView(int position, View convert, ViewGroup parent) {
            View v = convert;
            if (v == null) {
                v = getLayoutInflater().inflate(R.layout.row_line, parent, false);
            }
            Msg m = mRows.get(position);
            ((TextView) v.findViewById(R.id.row_title)).setText(m.out ? "YOU" : mAddress);
            ((TextView) v.findViewById(R.id.row_sub)).setText(m.body);
            return v;
        }
    }
}
