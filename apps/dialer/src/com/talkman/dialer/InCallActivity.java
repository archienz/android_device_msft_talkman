/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 */

package com.talkman.dialer;

import android.app.Activity;
import android.os.Bundle;
import android.telecom.Call;
import android.telecom.CallAudioState;
import android.telecom.InCallService;
import android.view.View;
import android.widget.TextView;

import java.util.List;

public class InCallActivity extends Activity {
    private static InCallActivity sOpen;
    private TextView mNumber;
    private TextView mState;

    static void finishIfOpen() {
        if (sOpen != null) {
            sOpen.finish();
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        sOpen = this;
        setContentView(R.layout.activity_incall);
        mNumber = findViewById(R.id.incall_number);
        mState = findViewById(R.id.incall_state);
        findViewById(R.id.btn_end).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Call c = firstCall();
                if (c != null) {
                    c.disconnect();
                }
                finish();
            }
        });
        findViewById(R.id.btn_mute).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                InCallService svc = TalkmanInCallService.instance;
                if (svc != null) {
                    CallAudioState s = svc.getCallAudioState();
                    svc.setMuted(s == null || !s.isMuted());
                    bind();
                }
            }
        });
        findViewById(R.id.btn_speaker).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                InCallService svc = TalkmanInCallService.instance;
                if (svc == null) {
                    return;
                }
                CallAudioState s = svc.getCallAudioState();
                int route = (s != null && s.getRoute() == CallAudioState.ROUTE_SPEAKER)
                        ? CallAudioState.ROUTE_EARPIECE
                        : CallAudioState.ROUTE_SPEAKER;
                svc.setAudioRoute(route);
                bind();
            }
        });
        Call c = firstCall();
        if (c != null && c.getState() == Call.STATE_RINGING) {
            c.answer(c.getDetails().getVideoState());
        }
        bind();
    }

    @Override
    protected void onDestroy() {
        if (sOpen == this) {
            sOpen = null;
        }
        super.onDestroy();
    }

    private Call firstCall() {
        InCallService svc = TalkmanInCallService.instance;
        if (svc == null) {
            return null;
        }
        List<Call> calls = svc.getCalls();
        return (calls == null || calls.isEmpty()) ? null : calls.get(0);
    }

    private void bind() {
        Call c = firstCall();
        if (c == null) {
            mNumber.setText("");
            mState.setText("");
            return;
        }
        if (c.getDetails() != null && c.getDetails().getHandle() != null) {
            mNumber.setText(c.getDetails().getHandle().getSchemeSpecificPart());
        }
        mState.setText(stateLabel(c.getState()));
    }

    private static String stateLabel(int state) {
        switch (state) {
            case Call.STATE_DIALING:
                return "DIALING";
            case Call.STATE_RINGING:
                return "RINGING";
            case Call.STATE_HOLDING:
                return "HOLD";
            case Call.STATE_ACTIVE:
                return "ACTIVE";
            case Call.STATE_CONNECTING:
                return "CONNECTING";
            default:
                return "";
        }
    }
}
