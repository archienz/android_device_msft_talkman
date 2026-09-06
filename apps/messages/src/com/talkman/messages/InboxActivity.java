/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.messages;

import android.Manifest;
import android.app.Activity;
import android.app.AlertDialog;
import android.app.role.RoleManager;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Telephony;
import android.text.InputType;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.TextView;

import java.util.ArrayList;
import java.util.List;

public class InboxActivity extends Activity {
    private static final String[] PERMS = {
            Manifest.permission.READ_SMS,
            Manifest.permission.SEND_SMS,
            Manifest.permission.RECEIVE_SMS,
            Manifest.permission.READ_CONTACTS
    };
    private final List<Conv> mRows = new ArrayList<Conv>();
    private RowAdapter mAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_inbox);
        ListView list = findViewById(R.id.list);
        mAdapter = new RowAdapter();
        list.setAdapter(mAdapter);
        list.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> p, View v, int pos, long id) {
                if (pos < mRows.size()) {
                    openThread(mRows.get(pos).address);
                }
            }
        });
        findViewById(R.id.btn_new).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                final EditText in = new EditText(InboxActivity.this);
                in.setInputType(InputType.TYPE_CLASS_PHONE);
                in.setHint(R.string.hint_to);
                in.setTextColor(0xFFE8E8E8);
                in.setHintTextColor(0x66E8E8E8);
                new AlertDialog.Builder(InboxActivity.this)
                        .setTitle(R.string.compose)
                        .setView(in)
                        .setPositiveButton(android.R.string.ok,
                                new android.content.DialogInterface.OnClickListener() {
                                    @Override
                                    public void onClick(android.content.DialogInterface d, int w) {
                                        openThread(in.getText().toString());
                                    }
                                })
                        .show();
            }
        });
        requestNeeded();
        maybeDefaultSms();
        applySendTo(getIntent());
    }

    @Override
    protected void onResume() {
        super.onResume();
        load();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        applySendTo(intent);
    }

    private void applySendTo(Intent intent) {
        if (intent == null || intent.getData() == null) {
            return;
        }
        String scheme = intent.getData().getScheme();
        if (scheme != null && (scheme.startsWith("sms") || scheme.startsWith("mms"))) {
            openThread(intent.getData().getSchemeSpecificPart());
        }
    }

    private void requestNeeded() {
        List<String> miss = new ArrayList<String>();
        for (String p : PERMS) {
            if (checkSelfPermission(p) != PackageManager.PERMISSION_GRANTED) {
                miss.add(p);
            }
        }
        if (!miss.isEmpty()) {
            requestPermissions(miss.toArray(new String[0]), 1);
        }
    }

    private void maybeDefaultSms() {
        RoleManager rm = getSystemService(RoleManager.class);
        if (rm != null && rm.isRoleAvailable(RoleManager.ROLE_SMS)
                && !rm.isRoleHeld(RoleManager.ROLE_SMS)) {
            startActivityForResult(rm.createRequestRoleIntent(RoleManager.ROLE_SMS), 2);
        }
    }

    private void openThread(String address) {
        if (address == null || address.trim().isEmpty()) {
            return;
        }
        Intent i = new Intent(this, ThreadActivity.class);
        i.putExtra(ThreadActivity.EXTRA_ADDRESS, address.trim());
        startActivity(i);
    }

    private void load() {
        mRows.clear();
        if (checkSelfPermission(Manifest.permission.READ_SMS)
                != PackageManager.PERMISSION_GRANTED) {
            mAdapter.notifyDataSetChanged();
            return;
        }
        Cursor c = getContentResolver().query(Telephony.Sms.Conversations.CONTENT_URI,
                new String[]{
                        Telephony.Sms.Conversations.SNIPPET,
                        Telephony.Sms.Conversations.THREAD_ID,
                        Telephony.Sms.Conversations.MESSAGE_COUNT
                },
                null, null,
                Telephony.Sms.Conversations.DEFAULT_SORT_ORDER);
        if (c == null) {
            loadInboxFallback();
            return;
        }
        try {
            while (c.moveToNext()) {
                long thread = c.getLong(1);
                Conv conv = new Conv();
                conv.snippet = c.getString(0);
                conv.address = addressForThread(thread);
                if (conv.address == null) {
                    conv.address = String.valueOf(thread);
                }
                conv.title = conv.address;
                mRows.add(conv);
            }
        } finally {
            c.close();
        }
        mAdapter.notifyDataSetChanged();
    }

    private void loadInboxFallback() {
        Cursor c = getContentResolver().query(Telephony.Sms.Inbox.CONTENT_URI,
                new String[]{Telephony.Sms.ADDRESS, Telephony.Sms.BODY},
                null, null, Telephony.Sms.DEFAULT_SORT_ORDER);
        if (c == null) {
            return;
        }
        try {
            int n = 0;
            while (c.moveToNext() && n < 40) {
                Conv conv = new Conv();
                conv.address = c.getString(0);
                conv.title = conv.address;
                conv.snippet = c.getString(1);
                mRows.add(conv);
                n++;
            }
        } finally {
            c.close();
        }
        mAdapter.notifyDataSetChanged();
    }

    private String addressForThread(long threadId) {
        Cursor c = getContentResolver().query(Telephony.Sms.CONTENT_URI,
                new String[]{Telephony.Sms.ADDRESS},
                Telephony.Sms.THREAD_ID + "=?",
                new String[]{String.valueOf(threadId)},
                Telephony.Sms.DEFAULT_SORT_ORDER + " LIMIT 1");
        if (c == null) {
            return null;
        }
        try {
            return c.moveToFirst() ? c.getString(0) : null;
        } finally {
            c.close();
        }
    }

    private static final class Conv {
        String title;
        String snippet;
        String address;
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
            Conv r = mRows.get(position);
            ((TextView) v.findViewById(R.id.row_title)).setText(r.title);
            ((TextView) v.findViewById(R.id.row_sub)).setText(r.snippet);
            return v;
        }
    }
}
