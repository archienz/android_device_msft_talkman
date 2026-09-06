/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.dialer;

import android.Manifest;
import android.app.Activity;
import android.app.role.RoleManager;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.net.Uri;
import android.os.Bundle;
import android.provider.CallLog;
import android.provider.ContactsContract;
import android.telecom.TelecomManager;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.BaseAdapter;
import android.widget.GridLayout;
import android.widget.ListView;
import android.widget.TextView;
import android.widget.Toast;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class DialerActivity extends Activity {
    private static final int REQ = 7;
    private static final String[] PERMS = {
            Manifest.permission.CALL_PHONE,
            Manifest.permission.READ_CONTACTS,
            Manifest.permission.READ_CALL_LOG
    };
    private static final String[] DIGITS = {
            "1", "2", "3", "4", "5", "6", "7", "8", "9", "*", "0", "#"
    };
    private static final String[] LETTERS = {
            "", "ABC", "DEF", "GHI", "JKL", "MNO", "PQRS", "TUV", "WXYZ", "", "+", ""
    };

    private TextView mDisplay;
    private TextView mTabRecents;
    private TextView mTabContacts;
    private ListView mList;
    private final StringBuilder mDigits = new StringBuilder();
    private boolean mContactsTab;
    private final List<Row> mRows = new ArrayList<Row>();
    private RowAdapter mAdapter;
    private final SimpleDateFormat mClock =
            new SimpleDateFormat("HH:mm", Locale.US);

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_dialer);
        mDisplay = findViewById(R.id.dial_display);
        mTabRecents = findViewById(R.id.tab_recents);
        mTabContacts = findViewById(R.id.tab_contacts);
        mList = findViewById(R.id.list);
        mAdapter = new RowAdapter();
        mList.setAdapter(mAdapter);
        mList.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> p, View v, int pos, long id) {
                if (pos >= 0 && pos < mRows.size()) {
                    placeCall(mRows.get(pos).number);
                }
            }
        });
        mTabRecents.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mContactsTab = false;
                paintTabs();
                loadList();
            }
        });
        mTabContacts.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mContactsTab = true;
                paintTabs();
                loadList();
            }
        });
        findViewById(R.id.btn_call).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                placeCall(mDigits.toString());
            }
        });
        buildPad();
        applyDialIntent(getIntent());
        requestNeeded();
        maybeDefaultDialer();
        bindDisplay();
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        applyDialIntent(intent);
        bindDisplay();
    }

    @Override
    protected void onResume() {
        super.onResume();
        loadList();
        if (mDigits.length() == 0) {
            bindDisplay();
        }
    }

    private void applyDialIntent(Intent intent) {
        if (intent == null) {
            return;
        }
        Uri data = intent.getData();
        if (data != null && "tel".equals(data.getScheme())) {
            String n = data.getSchemeSpecificPart();
            if (n != null) {
                mDigits.setLength(0);
                for (int i = 0; i < n.length(); i++) {
                    char c = n.charAt(i);
                    if (Character.isDigit(c) || c == '*' || c == '#' || c == '+') {
                        mDigits.append(c);
                    }
                }
            }
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
            requestPermissions(miss.toArray(new String[0]), REQ);
        }
    }

    private void maybeDefaultDialer() {
        RoleManager rm = getSystemService(RoleManager.class);
        if (rm != null && rm.isRoleAvailable(RoleManager.ROLE_DIALER)
                && !rm.isRoleHeld(RoleManager.ROLE_DIALER)) {
            startActivityForResult(rm.createRequestRoleIntent(RoleManager.ROLE_DIALER), 8);
        }
    }

    private void buildPad() {
        GridLayout pad = findViewById(R.id.pad);
        LayoutInflater inf = getLayoutInflater();
        for (int i = 0; i < DIGITS.length; i++) {
            final String d = DIGITS[i];
            View cell = inf.inflate(R.layout.key_cell, pad, false);
            GridLayout.LayoutParams lp = new GridLayout.LayoutParams();
            lp.width = 0;
            lp.height = (int) (64 * getResources().getDisplayMetrics().density);
            lp.columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f);
            lp.setMargins(6, 6, 6, 6);
            cell.setLayoutParams(lp);
            ((TextView) cell.findViewById(R.id.key_digit)).setText(d);
            ((TextView) cell.findViewById(R.id.key_letters)).setText(LETTERS[i]);
            cell.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    mDigits.append(d);
                    bindDisplay();
                }
            });
            cell.setOnLongClickListener(new View.OnLongClickListener() {
                @Override
                public boolean onLongClick(View v) {
                    if ("0".equals(d)) {
                        mDigits.append('+');
                        bindDisplay();
                        return true;
                    }
                    if (mDigits.length() > 0) {
                        mDigits.setLength(mDigits.length() - 1);
                        bindDisplay();
                        return true;
                    }
                    return false;
                }
            });
            pad.addView(cell);
        }
    }

    private void bindDisplay() {
        if (mDigits.length() == 0) {
            mDisplay.setText(mClock.format(new Date()));
        } else {
            mDisplay.setText(mDigits.toString());
        }
    }

    private void paintTabs() {
        mTabRecents.setTextColor(mContactsTab ? 0x66E8E8E8 : 0xFFE8E8E8);
        mTabContacts.setTextColor(mContactsTab ? 0xFFE8E8E8 : 0x66E8E8E8);
    }

    private void loadList() {
        mRows.clear();
        if (mContactsTab) {
            loadContacts();
        } else {
            loadRecents();
        }
        mAdapter.notifyDataSetChanged();
    }

    private void loadRecents() {
        if (checkSelfPermission(Manifest.permission.READ_CALL_LOG)
                != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        Cursor c = getContentResolver().query(CallLog.Calls.CONTENT_URI,
                new String[]{CallLog.Calls.NUMBER, CallLog.Calls.CACHED_NAME,
                        CallLog.Calls.TYPE, CallLog.Calls.DATE},
                null, null, CallLog.Calls.DEFAULT_SORT_ORDER);
        if (c == null) {
            return;
        }
        try {
            int n = 0;
            while (c.moveToNext() && n < 40) {
                String num = c.getString(0);
                String name = c.getString(1);
                Row r = new Row();
                r.number = num;
                r.title = TextUtils.isEmpty(name) ? num : name;
                r.sub = num == null ? "" : num;
                mRows.add(r);
                n++;
            }
        } finally {
            c.close();
        }
    }

    private void loadContacts() {
        if (checkSelfPermission(Manifest.permission.READ_CONTACTS)
                != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        Cursor c = getContentResolver().query(
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                new String[]{
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                        ContactsContract.CommonDataKinds.Phone.NUMBER
                },
                null, null,
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME + " ASC");
        if (c == null) {
            return;
        }
        try {
            int n = 0;
            while (c.moveToNext() && n < 80) {
                Row r = new Row();
                r.title = c.getString(0);
                r.number = c.getString(1);
                r.sub = r.number;
                mRows.add(r);
                n++;
            }
        } finally {
            c.close();
        }
    }

    private void placeCall(String number) {
        if (TextUtils.isEmpty(number)) {
            return;
        }
        if (checkSelfPermission(Manifest.permission.CALL_PHONE)
                != PackageManager.PERMISSION_GRANTED) {
            Toast.makeText(this, R.string.need_permission, Toast.LENGTH_SHORT).show();
            requestNeeded();
            return;
        }
        Uri uri = Uri.fromParts("tel", number, null);
        TelecomManager tm = getSystemService(TelecomManager.class);
        if (tm != null) {
            tm.placeCall(uri, null);
        } else {
            startActivity(new Intent(Intent.ACTION_CALL, uri));
        }
    }

    private static final class Row {
        String title;
        String sub;
        String number;
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
            Row r = mRows.get(position);
            ((TextView) v.findViewById(R.id.row_title)).setText(r.title);
            ((TextView) v.findViewById(R.id.row_sub)).setText(r.sub);
            return v;
        }
    }
}
