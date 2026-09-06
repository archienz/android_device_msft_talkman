# Talkman X-phone apps

Sideloadable product APKs. Do not replace SystemUI.apk on the 2026-09-01 zip.

| Module | Package | What |
| --- | --- | --- |
| TalkmanClock | com.talkman.clock | Void clock + home widget |
| TalkmanDialer | com.talkman.dialer | Keypad, recents, contacts, InCallService |
| TalkmanMessages | com.talkman.messages | SMS inbox/thread (default-SMS role) |
| TalkmanWidgets | com.talkman.widgets | Dock + date widgets |

Does not invent STARLINK. Camera dock uses the stock still-image intent (IMX230).
Does not `overrides` AOSP Dialer/Messaging until these hold the roles.
