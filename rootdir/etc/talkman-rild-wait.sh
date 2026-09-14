#!/system/bin/sh
# m338: auto hold-release then start rild after HLOS MPSS ONLINE.
# Sit-measured nodes (pil-msa.c / m266 / m295 / m337-director):
#   echo 3 > /sys/kernel/talkman_step     (AUTH need=3; never 2)
#   echo 0 > /sys/kernel/talkman_hold     (after-AUTH unhold)
#   MBA STATUS=00000003 / 00000004 in
#     /sys/module/pil_msa/parameters/talkman_mba  (also /sys/kernel/talkman_mba)
#   ONLINE: /sys/bus/msm_subsys/devices/subsys3/state
# Do not start rild before ONLINE. Do not RADIO_POWER from init.
# m350: persist.radio.no_wait_for_card=1 (blob @ 0x7B6E4C; nas_init
# stores u8 at nas_common_info+12). handle_card_transition @ 0x3F68C8
# skips WAITING_FOR_CARD_STATUS when card UNKNOWN (m349 hang). Does
# not skip UIM / does not force ABSENT. Never airplane. Never echo 2.
# Timeouts: do not loop forever (display/HWC must still work).
# m340: recover userdata qcril.db after /data, before rild (not odm).
# m345: after ONLINE start real ril-daemon (/vendor/bin/hw/rild) so
# hwservicemanager gets android.hardware.radio@1.1::IRadio/slot1
# (also 1.0).
# m346: this file is MS_BIND onto /vendor/bin/dumpstate_board.sh so it
# survives SwitchRoot/FreeRamdisk. Stock telephony-common.jar (no
# overlay bind — m345/m347 Phone SIGSEGV).
# m349: after ONLINE start ril-daemon ONLY. Do not start Phone yet.
# Call IRadio setRadioPower(true) via talkman-iradio-on (HIDL, not
# QMI). Then start com.android.phone.
# m350: set no_wait_for_card=1 + adb_log_on=1 before rild.
# Quiet: no dumpsys. Not a new QMI client. Author archienz.
# m373: wait.sh bind of stub libvss_nv_core.so never armed
# (FreeRamdisk; first-stage did not bind vendor lib64).
# m374: first-stage MS_BIND /dev/talkman-libvss_nv_core.so onto
# /vendor/lib64/libvss_nv_core.so (same pattern as rild.legacy.rc /
# dumpstate_board.sh). This script only confirms DST already has
# m373-vss-nv-stub, else bind from /dev or debug_ramdisk. Not odm.
# qcci_qmi_lge_vs_nv_init returns 0. No oat-hide. Author archienz.
# m380: do not hold Phone in a loop. No nas_init wait. No Phone-hold.
# On first IRadio up + short sleep (or CARDSTATE_PRESENT / USIM
# DETECTED if already in radio): immediately IRadio
# setUiccSubscription appIndex 0 activate true slot 0 via
# talkman-iradio-on setuicc — same HIDL as Phone, not a new QMI
# client. Then pm enable com.android.phone once and let Phone run.
# m379 never reached SET_UICC (hold/nas_init storm). Stock jar.
# m381: leftover /data/local/tmp/talkman-iradio-on is m349
# setRadioPower only (stole m380 SET_UICC). rm -f that path, then
# exec ONLY the first-stage vendor bind
# /vendor/bin/qmakernote-xtract (setUiccSubscription). Never tmp.
# m383: poll radio log until CARDSTATE_PRESENT or USIM DETECTED
# (cap ~25s), THEN qmakernote-xtract setuicc. Do not setuicc on
# card=0. Quiet logcat (-t 40 / 1s). No Phone-hold.
# Never overlay telephony-common. Author archienz.
# m387: persist.radio.multisim.config=dsds is a FIRST-STAGE
# /vendor/build.prop overlay (PropertyLoadBootDefaults). QCRIL
# nas/uim init property_get @ blob 0x79eab9 / 0x136cf0. Not a
# late setprop. Do not add UIM2. No second radio. RM-1118 out.
# m389: Phone first. pm enable, wait IRadio setResponseFunctions /
# RILJ / mRadioIndication not NULL (cap ~15s), wait PRESENT,
# then SET_UICC. Helper setuicc does not steal Phone callbacks.
# Do not SET_UICC with NULL indication. No helper card peek after
# Phone bound. No helper setRadioPower after Phone bound.
# m390: bind gate is NOT logcat -t 80 last-line compare (m389
# missed live RILJ / setResponseFunctions). Gate is pidof
# com.android.phone + lshal IRadio/slot1 clients>=1 / logcat -d
# grep setResponseFunctions. Then PRESENT, then SET_UICC.
# m391: SET_UICC when THIS SIT GET_SIM_STATUS CARDSTATE_PRESENT
# or helper peek card=1. Do not treat historical
# "m383 do not setuicc on card=0" as current (that string was a
# wait-start banner on m390; host aborted on it). After Phone
# bound + this-sit PRESENT/card=1: run setuicc once. Peek once
# before Phone (this sit card). After bind, poll logcat -d
# (not -t 40 / -t 80) for GET_SIM_STATUS CARDSTATE_PRESENT.
# m391 miss: stored full `logcat -d` in a shell var then grepped
# — PRESENT=n despite live CARDSTATE_PRESENT. Do not do that.
# m392: after Phone bound: sleep 4; then
#   logcat -b radio -d | grep -q CARDSTATE_PRESENT
# Do NOT assign full logcat to a variable. If yes (or 12s of
# 1s greps): /vendor/bin/qmakernote-xtract setuicc once.
# Ignore first peek card=0 (too early). Ignore stale m383
# banners. Quiet getprop gsm.* after. No dumpsys. Author archienz.
# m394: ss at first rild → RADIO_POWER complete, feature-2 OFF,
# GW 0xFFFF / gsm_id=-1 / change_subscription=0 / GET_IMSI=0.
# Same cache word: dsds⇒num_rilds=2 hang; ss⇒no change_subscription.
# Late ssss does not re-read (cbnz). Reset only after DMS property_set.
# m395 TWO-PHASE one sit (cite libril-qc-qmi-1.so 353b6bf2ec477e46dd6983271517989c):
#   qmi_ril_is_feature_supported @ 0x136ce0 property_get
#   persist.radio.multisim.config @ 0x79eab9 strncmp n=4:
#     dsds→cache=2  tsts→3  dsda→4
#     else (ss / ssss / empty / anything else)→cache=1
#     No ssss token in the blob. ss and ssss both hit else.
#   retrieve_number_of_rilds @ 0x160ec0 uses that cache.
# Phase1 FAST (m396; m395 USB-died in Phone bind wait before SET_UICC):
#   first-stage vendor/build.prop dsds (m387) + leftover-clear
#   setprop dsds BEFORE first ctl.start so first property_get is
#   feature-2 (change_subscription). Do NOT wait Phone bind.
#   Do NOT wait RADIO_POWER complete. Do NOT start Phone.
#   rild dsds → logcat -b radio -d | grep -q CARDSTATE_PRESENT
#   (m392 pipe, no logcat-in-var) → SET_UICC once (helper own
#   callbacks, m387 path) → GW 0x0 or 8s cap.
# Phase2 IMMEDIATELY: persist=ss then stop/start ril-daemon so NEW
#   process first property_get caches num_rilds=1. Do NOT wipe
#   provision. THEN pm enable Phone. Quiet getprop gsm.* / 50502.
# One rild only. No UIM2. No second radio. Author archienz.
# m398: remap unlocked PERSO->READY in vendor HIDL libril
# (hardware/ril/libril/ril_service.cpp getIccCardStatusResponse).
# First-stage MS_BIND /dev/talkman-libril.so onto
# /vendor/lib64/libril.so. This script confirms the marker, else
# bind from /dev or debug_ramdisk before first rild. Not a jar
# overlay. Not oat-hide. Not a QMI client.
# Phase1 SET_UICC before Phone bind (own callbacks). After phase2
# do NOT peek/setuicc — Phone keeps mRadioIndication and issues
# GET_SIM_STATUS / GET_IMSI. Author archienz.
# m411: first-stage auto two-phase ON the phone (no host adb SET_UICC).
# This file is still first-stage MS_BIND onto /vendor/bin/dumpstate_board.sh
# (m346 / m398 / m409 pack d0bc945c). Not /odm/etc/init (m308 ENOENT).
# After rild pid (skip lshal — full lshal each 0.3s lost the USB race):
#   logcat -b radio -d | grep -q CARDSTATE_PRESENT  (~5s, no var)
#   then /vendor/bin/qmakernote-xtract setuicc ONCE (own callbacks)
#   then GW 0x0 short cap (3s) then immediately persist ss + stop/start
#   ril-daemon (same phase2 as m396). rm leftover talkman-iradio-on.
# Do not steal IRadio after Phone bind. No dumpsys. Author archienz.
# m413: on-phone KEYCODE_WAKEUP (input keyevent 224) so SCREEN_STATE
# enable=1 can be true before RADIO_POWER / DMS ONLINE. m406 consider
# ran is_online=0 enable=0 while LPM; later SCREEN_STATE enable=1 but
# action_needed=0. Host keyevent (m407) cannot win the m409 ~9s USB
# death — wakeup lives here in dumpstate_board.sh. One early 224
# (as soon as this script can, before or right after rild pid). One
# more 224 after phase2 rild restart. Not a loop. Do not steal
# IRadio. No dumpsys. No host SET_UICC. Author archienz.
# m415: quiet PRESENT. m411/m413 1s logcat -d greps recreate the
# m409 host SET_UICC / USB / PS_HOLD death (~9s after ONLINE).
# getprop gsm.sim.state is UNKNOWN in phase1 (m396/m398) so it
# cannot gate SET_UICC. qcril.db recover is not a card-state
# file. No UIM PRESENT sysfs in this tree. Do not invent QMI.
# Path: sleep 5 (m396 first CARDSTATE ~4s after rild; 5s greps
# hit) then ONE logcat -b radio -d | grep -q. If miss: no SET_UICC
# (timeout documented); m439 still phase2 ss. No 1s loop.
# GW: sleep 1 then phase2 (no logcat; m396 GW waited=0). Same 9s window.
# Quiet sits (m403/m404, no logcat spam) held ~20s after LOADED.
# USB death after ONLINE is non-HLOS PS_HOLD (m267–m272, m409);
# do not invent RFCLK. This pack does not fix TZ. Author archienz.
# m439: PRESENT timeout / SET_UICC fail / ABSENT still phase2 ss
# (setprop persist.radio.multisim.config=ss + stop/start ril-daemon).
# m438 SIM-out skipped phase2 so persist stayed dsds; one rild then
# WAITING_FOR_MULTIPLE_RILD_SYNC and RADIO_POWER never ran.
# m394 ss-only completed RADIO_POWER without change_subscription.
# One setuicc only if this-sit PRESENT=y. Do not SET_UICC on
# timeout/ABSENT. Do not skip phase2. Two keyevent 224. No
# IRadio steal after Phone bind. No logcat loop. rm leftover
# talkman-iradio-on. Author archienz.
# m452: longer PRESENT. m415 sleep5+one-grep timed out every leftover=n
# sit of pack 548a9fa (m450/m451) with SIM claimed in: PRESENT=timeout,
# SET_UICC=n, gsm.sim=NOT_READY. m396 with SIM in saw PRESENT ~5s.
# Path: sleep 5 then three more sleep-5 greps (4 greps over ~20s).
# Not a 1s logcat -d loop. SET_UICC once if this-sit PRESENT=y.
# Timeout / SIM-out still phase2 ss (m439) so RADIO_POWER can complete.
# Keep: no IRadio steal after Phone bind, two keyevent 224, rm leftover
# iradio-on, no /odm/etc/init. Do not invent QMI. Never fake IN_SERVICE.
# Never overlay telephony-common. Author archienz.
# m457: helper setuicc is already blocking (HIDL
# setUiccSubscriptionResponse, up to 8s; rc=0 if the callback
# arrived). HIDL error is sys.talkman.set_uicc_err — helper rc=0
# is not HIDL error 0. Only set set_uicc=y when rc=0 AND err=0.
# Do not treat leftover m383/m381 done files as SET_UICC=y.
# Do not set SET_UICC=y on other helper rcs. Phase2 ss +
# stop/start still after helper returns, or after PRESENT
# timeout (m439). After phase2: one radio -d dump to a file
# and kmsg score lines (RADIO_POWER / SET_UICC / GW /
# DMS GET mode 0 / mVoiceRegState=0(IN_SERVICE)) so they survive
# radio-buffer rotate when USB dies. One-shot greps, not a 1s
# loop. Four spaced PRESENT greps stay. No IRadio steal. No
# /odm/etc/init. No invented QMI. Author archienz.
# m458: leftover set_uicc_err none/empty/0 counts as HIDL
# error 0 (m457 sit: HIDL error=0, getprop stayed none, packed
# c6eb7e49 set SET_UICC=n and skipped the 1s GW settle). After
# success: 1s GW settle then phase2. After phase2: sleep 1
# (was 3) so scores reach a +16s host dump before USB ~17s.
# Do not sit c6eb7e49 again. No IRadio steal. No invented QMI.
# Author archienz.
# m459: do not race phase2 past GW. After SET_UICC success
# (none/empty/0): two spaced greps (sleep 1 + grep, sleep 1
# + grep; not a 1s logcat loop). Phase2 if GW 0x0 landed
# (m397: GW can survive ss only if it landed) or after ~2s
# anyway. After phase2 ss + stop/start: force a real
# radio-power retry so Phone/RILJ sends setRadioPower(true)
# to the new ss rild. AOSP SST setRadioPower: if
# mDesiredPowerState already true and !forceApply, "Do
# nothing." RILJ RadioProxyDeathRecipient sets
# RADIO_POWER_UNAVAILABLE; setPowerStateToDesired only
# calls mCi.setRadioPower when state is RADIO_POWER_OFF
# (or forceApply). cmd phone on LOS 18.1 has no setRadioPower
# (ims/emergency/carrier-config only). Real user airplane
# off→on→off via settings + am broadcast
# android.intent.action.AIRPLANE_MODE flips
# mDesiredPowerState false then true. Never airplane persist
# as a fake camp. Never leave airplane on. Not IRadio steal
# after Phone bind. Not a QMI client. After retry: sleep 1
# then one-shot kmsg scores. Radio-file dump is logcat -t 80
# (short) so scores exist before USB death. Four PRESENT
# greps stay. rm leftover talkman-iradio-on. No /odm/etc/init.
# Author archienz.
# m460: drop the two GW greps. m459 proved GW never 0x0 in
# that window and those greps pushed phase2 past the +16s
# dump so air_retry never ran (dump caught mid phase2 rild
# restart). After SET_UICC success (none/empty/0): immediate
# phase2 ss + stop/start ril-daemon, then the same airplane
# off→on→off retry, then sleep 1 + one-shot kmsg scores
# (air_retry / RADIO_POWER Complete / DMS GET mode 0 / GW /
# gsm.sim / 50502 / persist ss / mVoiceRegState=0(IN_SERVICE)).
# Four spaced PRESENT greps stay. No IRadio steal. No invented
# QMI. No fake IN_SERVICE. No logcat 1s loop. Finish by
# ~kernel 24s / host +16–18s. Author archienz.
# m461: m460 airplane ran (air_retry=y) and did NOT produce
# RADIO_POWER Complete. After airplane off, Phone/RILJ logged
# no second setRadioPower / RADIO_POWER (wait.sh -t80
# on_true=n Complete=n; host radio -t200 is SMS on ss rild
# pid 2600 / RILJ 2209). persist ss WAS set before start
# ril-daemon (setprop ss then stop then start; order ok).
# Airplane DID use am broadcast AIRPLANE_MODE --ez state
# true|false (klogs omitted --ez; sequence was on then off,
# not an initial off). No live num_rilds /
# WAITING_FOR_MULTIPLE_RILD_SYNC / DMS GET after 19.375s.
# Late setprop ss without a new rild does not re-read QCRIL
# num_rilds cache — we already start a new rild after ss.
# am start on a live Phone is a no-op; SST mDesiredPowerState
# already true after the stuck dsds RADIO_POWER so airplane
# OFF is "Do nothing." Working sits (m396–m403) got Complete
# when Phone's first successful complete was on the ss rild.
# After ss then stop then start (never start before ss): wait
# rild pid, am force-stop com.android.phone, then start Phone
# so the first RADIO_POWER on the new rild is a fresh request.
# Real process restart, not overlay, not IRadio steal. Then
# airplane off→on→off with --ez state as a second kick.
# sleep 1 + kmsg scores (phone_rebind / air_retry /
# RADIO_POWER Complete / on_true / DMS GET mode 0 / GW /
# LOADED / 50502 / persist ss / mVoiceRegState=0(IN_SERVICE)).
# Finish by ~kernel 26s. Author archienz.
# m462: m461 proved rebound Phone never sent a second
# setRadioPower / RADIO_POWER (wait.sh -t80 on_true=n
# Complete=n; host radio SMS only on ss rild). SST already
# thought radio on, or IRadio not ready — airplane --ez was
# Do nothing. After ss then stop then start: force-stop
# com.android.phone, then helper IRadio.setRadioPower(true)
# WHILE Phone is down (same HIDL pattern as SET_UICC, not a
# steal). Do not take IRadio after Phone is back. Then allow
# Phone to come back. Airplane --ez only if helper cannot
# get a Complete. kmsg scores: helper_rp / RADIO_POWER
# Complete / DMS GET mode 0 / GW / LOADED / 50502 /
# persist ss / mVoiceRegState=0(IN_SERVICE). Finish by
# ~kernel 26s. Not a QMI client. Stock jar. Author archienz.
# m464: m463 leftover=n helper SET ONLINE at 21.97s
# (HIDL error=0). Host +22s radio was rebound Phone SST
# POWER_OFF (pollState radio=RADIO_POWER_OFF;
# hasAirplaneModeOnlChanged=false). No RADIO_POWER false
# in the late -t300 (rotated). No DMS GET mode 0 in that
# window. SST constructor: mDesiredPowerState =
# enableCellularOnBoot && !airplane_mode_on. If leftover
# airplane_mode_on=1, rebound Phone desired=false and
# may send setRadioPower(false) or stay POWER_OFF.
# ITelephony.setRadioPower(true) is transaction 18 on
# this tree ITelephony.aidl (setRadio=16,
# setRadioForSubscriber=17, setRadioPower=18) →
# PhoneInterfaceManager.setRadioPower →
# defaultPhone.setRadioPower. cmd phone has no
# radio-power (ims/emergency/carrier-config only).
# SST.setRadioPower Do nothing if desired already
# matches (forceApply=false). After helper SET ONLINE:
# one-shot kmsg HIDL + logcat -b radio -d (DMS GET /
# mode / POST_OPRT / RADIO_POWER) so GET 0 cannot
# rotate. Then leftover airplane 1→0 + --ez false
# (before Phone so SST init sees 0). Start Phone. Do
# not take IRadio after bind. If SST still POWER_OFF:
# service call phone 18 i32 0 then i32 1 (local desired
# flip; radio already OFF so false is not a modem off).
# Not a jar overlay. Not a QMI client. Author archienz.
# m466: m465 leftover=n GET 0 held; ITelephony txn 18
# IS setRadioPower(boolean) on this tree ITelephony.aidl
# (method 18; setRadio=16; FIRST_CALL_TRANSACTION+17=18;
# PhoneInterfaceManager.setRadioPower → defaultPhone;
# Parcel 00000000 00000001 = no exception, true). SST
# stayed POWER_OFF because the call ran ~1.5s after
# Phone pid while radioService[0]->mRadioResponse ==
# NULL (and mRadioIndication NULL). RILJ DID send
# RADIO_POWER on=true; HIDL dropped the response and
# UNSOL RADIO_STATE_CHANGED. getRadioState=0 despite
# DMS GET 0 — Phone never consumed RADIO_ON. Helper
# HIDL death can clear mRadioResponse after Phone
# bind if Phone starts too soon. After helper SET
# ONLINE + leftover airplane: sleep 1 (helper pid
# gone / death settle) THEN start Phone. After Phone
# pid: sleep 2 then -t 80 (RILJ / setResponseFunctions)
# THEN txn 18. Do not take IRadio after bind. If
# getRadioState already ON: only i32 1 (false would
# power the modem off and undo GET 0). Else i32 0
# then i32 1. One-shot kmsg: txn, reply, SST, get0,
# gsm.sim.state, 50502, mVoiceRegState, radio_state.
# Not a QMI client. Stock jar. Author archienz.
# m467: m466 GET 0 held but Phone never consumed RADIO_ON
# (getRadioState=0, mRadioResponse==NULL, SST POWER_OFF).
# Helper HIDL setRadioPower while Phone down owned
# setResponseFunctions; after helper death Phone rebound
# with NULL callbacks so txn 18 was dropped. Phone must be
# the IRadio client before RADIO_ON is expected.
# Order: PRESENT + SET_UICC (helper Completes, releases
# IRadio, exits) → setprop ss THEN stop THEN start
# ril-daemon → do NOT helper setRadioPower → do NOT
# force-stop Phone after ss rild → spaced greps (2–4
# over ~4s, not a 1s loop) for setResponseFunctions /
# RadioIndication / mRadioResponse non-NULL → then
# service call phone 18 i32 1. Never txn 18 while
# mRadioResponse==NULL. Leftover airplane 1→0 + --ez
# false only if airplane_mode_on is 1. No invented QMI.
# No fake IN_SERVICE. Author archienz.
# m468: slim the wait so bind + txn 18 + kmsg scores
# finish before a host +20s dump. m467 leftover
# settings get burned ~5s (21.73→27.03); Phone
# start 27.26s; dump landed during those klogs —
# bind greps / txn 18 / rild_wait=3 never reached.
# Use getprop persist.radio.airplane_mode_on once;
# only broadcast if it is 1. No settings stall.
# Bind wait: two spaced greps (sleep 1 + grep,
# sleep 1 + grep), not 4s×N and not a 1s loop.
# Fire txn 18 after first bind hit OR after the
# two greps even if bind string missing (do not
# skip txn 18). Immediate kmsg scores: bind_seen,
# txn18, getRadioState, RADIO_ON, DMS GET 0, SST,
# gsm.sim, 50502, mVoiceRegState. Complete by
# ~kernel 24s. Same architecture: Phone is IRadio
# client, no helper setRadioPower, no force-stop.
# Author archienz.
# m482: m474 libril death-cookie + m465/m471 helper
# GET 0 while Phone down. Order after PRESENT+SET_UICC
# + helper release and ss then stop then start:
#   force-stop Phone
#   helper setRadioPower(true) while Phone down → GET 0
#   helper setResponseFunctions(null)+exit
#   wait until Phone pid gone (already force-stopped)
#   start Phone, sleep 3 (no bind logcat loop)
#   leftover air getprop once
#   service call phone 18 i32 1
#   one-shot kmsg: GET 0, txn18, RADIO_ON, bind, SST,
#   50502, nas67, IN_SERVICE
# Death cookie so helper release cannot wipe a later
# Phone bind (m466). No bind logcat (8126f0ab).
# Host dump +20s. Cap 3 sits. Author archienz.
# m483: do not block on Phone pid empty. m482 leftover=n
# sits: wait_svc=running rild_wait=2 at +20s (pid-wait past
# dump; sit2 helper then second pid-wait; txn18 never).
# After PRESENT+SET_UICC + helper release and ss then stop
# then start:
#   am force-stop com.android.phone
#   sleep 1
#   helper setRadioPower(true) while Phone down → GET 0
#   helper setResponseFunctions(null)+exit
#   am start Phone (or let it restart)
#   leftover air getprop once
#   sleep 2
#   service call phone 18 i32 1
#   one-shot kmsg: GET 0, txn18, bind, SST, 50502, nas67,
#   IN_SERVICE
# Keep PRESENT+SET_UICC+ss rild+death-cookie libril.
# No bind logcat. Finish ~kernel 24s. Host dump +20s.
# Cap 3 sits. Author archienz.
# m484: sit1 cookie did not reject Phone bind (no serviceDied /
# ignore stale / cleared). bind miss was Phone never calling
# setResponseFunctions (m474 klog absent). GET 0 missed dump
# (helper SET ONLINE 22.98s, no DMS GET / operating mode 0).
# Keep death-cookie libril. Slim wait: force-stop, sleep 1,
# helper setRadioPower, release, start Phone, leftover air,
# sleep 2, txn 18. Score get0=y if DMS GET mode 0 OR helper
# SET ONLINE + operating mode 0 this sit. Host radio -t 400.
# Author archienz.
# m485: m484 sit1/2 helper SET ONLINE + operating mode 0
# = get0=y; txn18=y Parcel true; Phone never called
# setResponseFunctions; cookie stayed (no serviceDied
# reject). After helper (or first rild), IRadio is a
# stale HIDL instance Phone will not adopt. Order:
#   PRESENT + SET_UICC + release
#   setprop ss; stop; start ril-daemon
#   force-stop Phone; sleep 1
#   helper setRadioPower; release; exit
#   stop; start ril-daemon again (fresh IRadio;
#   GET 0 may drop — Phone txn 18 must re-ONLINE)
#   start Phone; leftover air once; sleep 3
#   one-shot kmsg: lshal/IRadio if cheap,
#   RILJ/RadioService/setResponseFunctions/RadioImpl
#   service call phone 18 i32 1
#   scores: GET 0, txn18, bind (only
#   setResponseFunctions or RadioResponse
#   registered — not "missing"), SST, 50502,
#   IN_SERVICE
# No bind logcat loop. Finish ~kernel 26s.
# Keep death-cookie libril. Author archienz.
# m489: Phone never called setResponseFunctions after ss
# rild restart (m481/m484). GET 0 works via helper (m484).
# SST OOS + 50502 works without helper (m481). Phone-first:
#   PRESENT + SET_UICC + helper release
#   setprop ss
#   force-stop Phone; start Phone (RILJ up, getService
#   will retry)
#   THEN stop; start ril-daemon (IRadio appears while
#   Phone is already polling)
#   leftover air once; sleep 2
#   helper setRadioPower only if Phone still not bound
#   after 2s (Phone down? skip — do not steal if bind
#   already). Prefer: no helper IRadio if Phone is up.
#   txn 18 after sleep 2
#   one-shot kmsg scores
# No bind logcat loop. No pid-empty wait.
# Keep death-cookie libril. Host dump +20s. Author archienz.
# m494: m489 Phone-first + one-shot greps NAS 0x67 /
# is_online / FORCE_NW_SEARCH into kmsg (not a loop;
# do not send 0x67). Host dmesg dump can score nas67
# if USB/radio logcat is gone. Author archienz.
# m509: Phone-first wait, not Phone-first on a live phase1
# IRadio. AOSP RILJ (stock jar) getRadioProxy() calls
# IRadio.getService("slot1", true) once; there is no
# IServiceNotification. retry=true waits only while
# IRadio is down (VINTF radio 1.1). If phase1 rild is
# still registered after persist=ss, Phone binds that
# dying client (klog "non-null ss" is a false bind) or
# races its death into mDisabledRadioServices and never
# calls setResponseFunctions on the ss process. txn 18
# can still Parcel true (SST "Do nothing" unless
# RADIO_POWER_OFF). Order: persist ss, stop phase1
# rild, force-stop Phone, start Phone (getService
# waits), start ss rild (registerAsService unblocks
# setResponseFunctions). No pid-empty wait. No helper
# IRadio after Phone is up. No jar overlay. Author archienz.
# m511: after Phone bind + GET 0, one KEYCODE_WAKEUP so
# Phone sendDeviceState → HIDL SCREEN_STATE → blob
# consider @ 0x39d7f8 with is_online=1 enable=1 (sole
# bl 0x409724 / NAS 0x67). persist force_nw_search=1
# already. Do not send 0x67. Do not steal IRadio.
# Phase2 keyevent stays before RADIO_POWER. This third
# keyevent is after txn 18 + scored GET 0 + new m474
# non-null ss. Not a loop. Not a fake PLMN. Author
# archienz.
# m474: Phone IRadio client. libril linkToDeath cookie so
# helper setResponseFunctions(null)+exit cannot wipe a
# later Phone bind (m466). wait.sh: after ss rild, force-stop
# Phone, wait pid empty (cap 2s, 0.25 steps — not logcat),
# leftover air getprop-once, start Phone, wait pid, sleep 3,
# one-shot dmesg for "m474 setResponseFunctions non-null ss"
# (phase1 helper is dsds; Phone bind is ss), then txn 18.
# Still no helper setRadioPower. Still no bind logcat.
# Next sit m474 first; fallback m473/30786136; never sit
# 8126f0ab. Host dump +18s. Author archienz.
# m473: Phone-owned RADIO_POWER (no helper setRadioPower).
# PRESENT + SET_UICC + helper release/exit, setprop ss THEN
# stop THEN start ril-daemon, force-stop Phone (fresh RILJ
# on the ss rild), leftover air getprop once (broadcast
# only if 1), start Phone, sleep 3 (NOT bind logcat greps),
# service call phone 18 i32 1, one-shot kmsg scores
# (txn18, GET 0, RADIO_ON, SST, gsm.sim, 50502,
# IN_SERVICE). No IRadio steal. No invented QMI. No fake
# IN_SERVICE. No 1s logcat loop. No extra radio file dumps
# (no GET0F/BIND/SCORE/m350-radio.txt). Next sit m473
# first; fallback m471/ccda8378; never sit 8126f0ab.
# Host dump +18s. Author archienz.
# m471: slim GET 0 path that dumps. PRESENT + SET_UICC +
# helper release, setprop ss THEN stop THEN start ril-daemon,
# force-stop Phone, helper setRadioPower(true) while Phone
# down, helper setResponseFunctions(null)+exit, start Phone,
# sleep 2 (NOT bind logcat greps), leftover air getprop once
# (broadcast only if 1), service call phone 18 i32 1, one-shot
# kmsg scores (GET 0, txn18, RADIO_ON, SST, gsm.sim, 50502,
# IN_SERVICE). No 1s logcat loop. No extra radio file dumps
# on-device (no GET0F/BIND/SCORE/m350-radio.txt). m469/m470
# pack 8126f0ab USB-died after bind logcat; do not sit it.
# Helper release before Phone bind so death cannot leave
# mRadioResponse==NULL (m466). Host dump +18s. Author archienz.
# m469: combine GET 0 + Phone IRadio client + txn 18.
# PRESENT + SET_UICC + helper exit/release, then setprop ss
# THEN stop THEN start ril-daemon. Prefer: force-stop Phone
# → helper setRadioPower(true) while Phone down → helper
# release/exit → start Phone → two spaced bind greps →
# service call phone 18 i32 1. Helper must be dead before
# Phone setResponseFunctions. Do not steal IRadio after
# bind. m468: slim wait finished ~25s; Phone pid 2214 kept
# a dead IRadio client (bind greps missed setResponseFunctions
# / RadioImpl / hidl; radio -t300 was RILJ [PHONE0] SMS only;
# txn 18 Parcel true; get0=n RADIO_ON=n). m465/m466: helper
# power while Phone down → DMS GET mode 0, then helper death
# left mRadioResponse==NULL so RADIO_ON dropped. Bind wait
# uses this tree RILJ/libril: D RILJ / [PHONE0] /
# getRadioProxy / setResponseFunctions (RadioImpl RLOGD).
# Do not score bind=y on helper setResponseFunctions(null)
# or mRadioResponse==NULL. Leftover air: getprop once (no
# 5s settings). Finish ~kernel 26s. Author archienz.

S3=/sys/bus/msm_subsys/devices/subsys3/state
STEP=/sys/kernel/talkman_step
HOLD=/sys/kernel/talkman_hold
MBA=/sys/module/pil_msa/parameters/talkman_mba
MBA2=/sys/kernel/talkman_mba

klog() {
    echo "$1" > /dev/kmsg
}

read_mba() {
    m=""
    if [ -r "$MBA" ]; then
        m=`cat "$MBA" 2>/dev/null`
    elif [ -r "$MBA2" ]; then
        m=`cat "$MBA2" 2>/dev/null`
    fi
    echo "$m" | tr -d '\r'
}

read_s3() {
    s=""
    if [ -r "$S3" ]; then
        s=`cat "$S3" 2>/dev/null`
    fi
    echo "$s" | tr -d '\r\n '
}

stop_rild_if_running() {
    ril=`getprop init.svc.ril-daemon`
    if [ "$ril" = running ]; then
        setprop ctl.stop ril-daemon
        klog "m338 auto-hold stop ril-daemon before ONLINE"
    fi
}

# m380: do not hold Phone in a loop. No disable-user. No force-stop storm.
# m367 hold phone / m368 disable-user / sticky_disable removed.
# m351 wait nas_init skipped — SET_UICC immediately after IRadio.

bind_vss_nv_stub() {
    # m374: confirm first-stage vendor bind first. DST-first so a
    # missing ramdisk copy cannot set vss=9 over a live stub bind.
    # Vendor lib64 only. Not odm. Bind only. No unlink.
    STUB=/data/local/tmp/talkman-libvss_nv_core.so
    DEVSTUB=/dev/talkman-libvss_nv_core.so
    DST=/vendor/lib64/libvss_nv_core.so
    if grep -q 'm373-vss-nv-stub' "$DST" 2>/dev/null; then
        klog "m374 vss-nv stub already on $DST (first-stage bind)"
        setprop sys.talkman.vss_stub 1
        return
    fi
    mkdir -p /data/local/tmp 2>/dev/null
    src=
    if [ -s "$DEVSTUB" ]; then
        src=$DEVSTUB
    fi
    if [ -z "$src" ] && [ -s /debug_ramdisk/talkman-libvss_nv_core.so ]; then
        src=/debug_ramdisk/talkman-libvss_nv_core.so
    fi
    if [ -z "$src" ] && [ -s /talkman-libvss_nv_core.so ]; then
        src=/talkman-libvss_nv_core.so
    fi
    # Footer marker is a lone line. Split so the extract grep is not
    # itself a payload start. Pack appends under #M374_VSS_HAVE.
    have="#""M374_VSS_HAVE"
    have_end="#""M374_VSS_HAVE_END"
    if [ -z "$src" ] && grep -q "^${have}$" "$0" 2>/dev/null; then
        sed -n "/^${have}$/,/^${have_end}$/p" "$0" | sed '1d;$d' | base64 -d > "$DEVSTUB" 2>/dev/null
        if [ -s "$DEVSTUB" ]; then
            src=$DEVSTUB
        fi
    fi
    if [ -n "$src" ]; then
        cp "$src" "$STUB" 2>/dev/null
        if [ "$src" != "$DEVSTUB" ]; then
            cp "$src" "$DEVSTUB" 2>/dev/null
        fi
    fi
    if [ ! -s "$STUB" ] && [ -s "$DEVSTUB" ]; then
        STUB=$DEVSTUB
    fi
    if [ ! -s "$STUB" ]; then
        klog "m374 vss-nv stub missing — no bind"
        setprop sys.talkman.vss_stub 9
        return
    fi
    chmod 644 "$STUB" 2>/dev/null
    if [ ! -e "$DST" ]; then
        klog "m374 vss-nv stub dst ENOENT $DST — not odm, no unlink"
        setprop sys.talkman.vss_stub 8
        return
    fi
    if grep -q 'm373-vss-nv-stub' "$DST" 2>/dev/null; then
        klog "m374 vss-nv stub already on $DST"
        setprop sys.talkman.vss_stub 1
        return
    fi
    ctx=`getfilecon "$DST" 2>/dev/null`
    ctx=`printf '%s\n' "$ctx" | awk '{print $NF}'`
    if [ -n "$ctx" ]; then
        chcon "$ctx" "$STUB" 2>/dev/null
    fi
    if mount -o bind "$STUB" "$DST" 2>/dev/null || mount --bind "$STUB" "$DST" 2>/dev/null; then
        klog "m374 vss-nv stub bind-mounted onto $DST"
        setprop sys.talkman.vss_stub 1
    else
        klog "m374 vss-nv stub bind failed $DST"
        setprop sys.talkman.vss_stub 7
    fi
}


bind_libril_remap() {
    # m398: confirm first-stage vendor bind first. DST-first so a
    # missing ramdisk copy cannot clobber a live remap bind.
    # Vendor lib64 only. Bind only. No unlink. No jar overlay.
    STUB=/data/local/tmp/talkman-libril.so
    DEVSTUB=/dev/talkman-libril.so
    DST=/vendor/lib64/libril.so
    if grep -q 'm398 remap unlocked PERSO->READY' "$DST" 2>/dev/null; then
        klog "m398 remap libril already on $DST (first-stage bind)"
        setprop sys.talkman.libril_remap 1
        return
    fi
    mkdir -p /data/local/tmp 2>/dev/null
    src=
    if [ -s "$DEVSTUB" ]; then
        src=$DEVSTUB
    fi
    if [ -z "$src" ] && [ -s /debug_ramdisk/talkman-libril.so ]; then
        src=/debug_ramdisk/talkman-libril.so
    fi
    if [ -z "$src" ] && [ -s /talkman-libril.so ]; then
        src=/talkman-libril.so
    fi
    have="#""M398_LIBRIL_HAVE"
    have_end="#""M398_LIBRIL_HAVE_END"
    if [ -z "$src" ] && grep -q "^${have}$" "$0" 2>/dev/null; then
        sed -n "/^${have}$/,/^${have_end}$/p" "$0" | sed '1d;$d' | base64 -d > "$DEVSTUB" 2>/dev/null
        if [ -s "$DEVSTUB" ]; then
            src=$DEVSTUB
        fi
    fi
    if [ -n "$src" ]; then
        cp "$src" "$STUB" 2>/dev/null
        if [ "$src" != "$DEVSTUB" ]; then
            cp "$src" "$DEVSTUB" 2>/dev/null
        fi
    fi
    if [ ! -s "$STUB" ] && [ -s "$DEVSTUB" ]; then
        STUB=$DEVSTUB
    fi
    if [ ! -s "$STUB" ]; then
        klog "m398 remap libril missing — no bind"
        setprop sys.talkman.libril_remap 9
        return
    fi
    if ! grep -q 'm398 remap unlocked PERSO->READY' "$STUB" 2>/dev/null; then
        klog "m398 remap libril src missing marker — no bind"
        setprop sys.talkman.libril_remap 8
        return
    fi
    chmod 644 "$STUB" 2>/dev/null
    if [ ! -e "$DST" ]; then
        klog "m398 remap libril dst ENOENT $DST — no unlink"
        setprop sys.talkman.libril_remap 8
        return
    fi
    ctx=`getfilecon "$DST" 2>/dev/null`
    ctx=`printf '%s\n' "$ctx" | awk '{print $NF}'`
    if [ -n "$ctx" ]; then
        chcon "$ctx" "$STUB" 2>/dev/null
    fi
    if mount -o bind "$STUB" "$DST" 2>/dev/null || mount --bind "$STUB" "$DST" 2>/dev/null; then
        klog "m398 remap unlocked PERSO->READY libril bind-mounted onto $DST"
        setprop sys.talkman.libril_remap 1
    else
        klog "m398 remap libril bind failed $DST"
        setprop sys.talkman.libril_remap 7
    fi
}

klog "m338 auto-hold wait start"
klog "m346 wait vendor-bind /vendor/bin/dumpstate_board.sh"
klog "m411 auto two-phase bound /vendor/bin/dumpstate_board.sh (no host SET_UICC)"
klog "m413 auto wakeup keyevent 224 bound /vendor/bin/dumpstate_board.sh (on-phone; no host SET_UICC)"
klog "m415 quiet PRESENT sleep5+one-logcat bound /vendor/bin/dumpstate_board.sh (no 1s logcat loop; no host SET_UICC)"
klog "m439 phase2 on timeout/fail/ABSENT bound /vendor/bin/dumpstate_board.sh (do not skip phase2; one setuicc only if PRESENT)"
klog "m452 longer PRESENT sleep5+4spaced-greps20s bound /vendor/bin/dumpstate_board.sh (no 1s logcat loop; SET_UICC once on PRESENT; phase2 on timeout)"
klog "m457 set_uicc=y only HIDL error 0; phase2 after helper rc; post-phase2 kmsg scores bound /vendor/bin/dumpstate_board.sh (no 1s logcat loop)"
klog "m458 leftover none/empty/0 = HIDL err 0; post-phase2 sleep 1 then kmsg scores bound /vendor/bin/dumpstate_board.sh (no 1s logcat loop)"
klog "m459 two spaced GW greps then phase2; airplane off-on-off RADIO_POWER retry; short -t 80 scores bound /vendor/bin/dumpstate_board.sh (no 1s logcat loop)"
klog "m460 drop GW greps; immediate phase2 then airplane off-on-off; sleep 1 scores bound /vendor/bin/dumpstate_board.sh (no 1s logcat loop)"
klog "m461 phone_rebind after ss rild; airplane --ez off-on-off; sleep 1 scores bound /vendor/bin/dumpstate_board.sh (no 1s logcat loop)"
klog "m462 helper setRadioPower while Phone down after ss rild; airplane only if no Complete; sleep 1 scores bound /vendor/bin/dumpstate_board.sh (no 1s logcat loop)"
klog "m464 post-online kmsg then leftover airplane then ITelephony.setRadioPower txn=18 if POWER_OFF bound /vendor/bin/dumpstate_board.sh (no IRadio after bind; no 1s logcat loop)"
klog "m466 helper death settle then Phone then IRadio/RILJ bind then ITelephony.setRadioPower txn=18 (AIDL method 18) bound /vendor/bin/dumpstate_board.sh (no IRadio after bind; no 1s logcat loop)"
klog "m467 Phone IRadio client on ss rild then ITelephony.setRadioPower txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (no helper power; no force-stop; no IRadio steal; no 1s logcat loop)"
klog "m468 slim wait getprop leftover air + two bind greps then txn=18 always then immediate kmsg scores bound /vendor/bin/dumpstate_board.sh (no settings stall; no skip txn 18; no helper power; no force-stop; no 1s loop)"
klog "m469 force-stop then helper setRadioPower then helper release then Phone bind then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (GET 0 + Phone IRadio client; no steal after bind; no 1s loop)"
klog "m509 PRESENT+SET_UICC+helper release then setprop ss then stop phase1 ril-daemon then force-stop then start Phone then start ss ril-daemon then leftover air then sleep 2 then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (Phone-first wait: IRadio down so getService(slot1,true) waits; bind only new m474 non-null ss; no helper if Phone up; no pid-empty wait; no 1s loop)"
klog "m489 PRESENT+SET_UICC+helper release then setprop ss then force-stop then start Phone then stop/start ril-daemon then leftover air then sleep 2 then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (Phone-first; IRadio appears while Phone polling; helper only if unbound after 2s and Phone not down; no steal if bind already; prefer no helper IRadio if Phone up; no bind logcat; no pid-empty wait; no 1s loop)"
klog "m494 one-shot greps NAS 0x67 / is_online / FORCE_NW_SEARCH into kmsg bound /vendor/bin/dumpstate_board.sh (not a loop; do not send 0x67; Phone-first m489)"
klog "m511 after Phone bind + GET 0 keyevent 224 SCREEN_STATE re-queue consider bound /vendor/bin/dumpstate_board.sh (not a loop; do not send 0x67; Phone-owned IRadio)"
klog "m489 diag m484/m481: leftover=n Phone never setResponseFunctions after ss rild; GET 0 via helper m484; SST OOS+50502 without helper m481"
klog "m485 PRESENT+SET_UICC+ss rild then force-stop then sleep 1 then helper setRadioPower then helper setResponseFunctions(null)+exit then stop/start ril-daemon then start Phone then leftover air then sleep 3 then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (fresh IRadio; GET 0 may drop; Phone txn 18 re-ONLINE; bind only setResponseFunctions/RadioResponse registered; no bind logcat; no radio files; no 1s loop)"
klog "m485 diag m484: leftover=n pack 325f6b94 sit1/2 helper SET ONLINE + operating mode 0 get0=y txn18=y Parcel true; Phone never setResponseFunctions; cookie stayed; 50502=n gsm.sim=READY op empty; sit3 USB died +20s"
klog "m484 force-stop then sleep 1 then helper setRadioPower then helper setResponseFunctions(null)+exit then start Phone then leftover air then sleep 2 then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (keep death cookie; GET 0 from helper SET ONLINE operating mode 0; no bind logcat; no radio files; no 1s loop)"
klog "m484 diag m483: leftover=n sit1 USB alive wait ~26s helper_rp=y SET ONLINE 22.98s txn18=y Parcel true; get0=n no DMS GET/operating mode 0; bind=n cookie miss not reject; sit2/3 USB died +20s"
klog "m483 force-stop then sleep 1 then helper setRadioPower then helper setResponseFunctions(null)+exit then start Phone then leftover air then sleep 2 then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (no pid-empty wait; m474 death cookie + GET 0; no bind logcat; no radio files; no 1s loop)"
klog "m483 diag m482: leftover=n +20s wait_svc=running rild_wait=2; pid stayed non-empty after force-stop; sit2 helper GET 0 + SST OUT_OF_SERVICE; sit1/3 dumped before helper; txn18=n bind=n"
klog "m482 force-stop then helper setRadioPower then helper setResponseFunctions(null)+exit then wait pid-empty then sleep 3 then leftover air then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (m474 death cookie + GET 0; no bind logcat; no radio files; no 1s loop)"
klog "m482 diag m481: leftover=n +18s LOADED+50502 txn18=y sst=OUT_OF_SERVICE get0=n bind=n helper_rp=n; Phone pid empty=n; no RADIO_POWER/GET0 after txn18 (not rotated)"
klog "m474 force-stop wait-pid-empty then leftover air then sleep 3 then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (libril death cookie; Phone-owned RADIO_POWER; no helper power; no bind logcat; no radio files; no 1s loop)"
klog "m474 diag m473: pack 30786136 never sat; keep fallback (force-stop + sleep 3 + txn 18; no helper power)"
klog "m473 force-stop then leftover air then sleep 3 then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (Phone-owned RADIO_POWER; no helper power; no bind logcat; no radio files; no 1s loop)"
klog "m473 diag m471: pack ccda8378 never sat; keep fallback (helper rp + release + sleep 2 + txn 18)"
klog "m473 diag m470: USB died +16s NONE after bind logcat pack 8126f0ab; do not sit 8126f0ab"
klog "m473 diag m469: USB died +20s BootMgr after bind logcat pack 8126f0ab"
klog "m473 diag m468: LOADED+50502 txn 18 Parcel true; Phone never bound IRadio; get0=n"
klog "m473 diag m466: GET 0 held; txn 18 Parcel true; mRadioResponse==NULL; RADIO_ON dropped (helper stole IRadio)"
klog "m473 diag m465: helper setRadioPower while Phone down → GET 0 then mRadioResponse==NULL; RADIO_ON dropped; SST POWER_OFF"
klog "m471 force-stop then helper setRadioPower then helper setResponseFunctions(null)+exit then sleep 2 then txn=18 i32 1 bound /vendor/bin/dumpstate_board.sh (no bind logcat; no radio files; no 1s loop)"
klog "m471 diag m470: USB died +16s NONE after bind logcat pack 8126f0ab; do not sit 8126f0ab"
klog "m471 diag m469: USB died +20s BootMgr after bind logcat pack 8126f0ab"
klog "m471 diag m468: LOADED+50502 txn 18 Parcel true; Phone never bound IRadio; get0=n"
klog "m471 diag m466: GET 0 held; txn 18 Parcel true; mRadioResponse==NULL; RADIO_ON dropped"
klog "m471 diag m465: quiet +20s dump GET 0 + RADIO_POWER Complete + SST POWER_OFF + txn 18"
klog "m469 diag m468: bind 1/2+2/2 miss; radio had RILJ [PHONE0] SMS not setResponseFunctions/RadioImpl; txn 18 Parcel true; get0=n RADIO_ON=n"
klog "m468 diag m467: leftover settings get burned ~5s (21.73-27.03); Phone start 27.26s; host +20s dump before bind/txn18/rild_wait=3"
klog "m466 diag m465: txn 18 IS setRadioPower(boolean); Parcel true; getRadioState=0; RILJ RADIO_POWER on=true; mRadioResponse==NULL; UNSOL radio state dropped; SST POWER_OFF"
klog "m467 diag m466: helper setRadioPower while Phone down owned IRadio; after helper death mRadioResponse==NULL so RADIO_ON dropped; GET 0 held; SST POWER_OFF"
klog "m464 diag m463: helper SET ONLINE 21.97s then rebound Phone SST POWER_OFF; no RADIO_POWER false in +22s -t300; no DMS GET 0 (rotated or never); leftover airplane_mode_on unchecked"
klog "m462 diag m461: after Phone rebind (21.99s) RILJ/IRadio logged NO second setRadioPower / on_true (SST already on or IRadio not ready; not Complete=n on a second request)"
klog "m461 diag m460: after airplane off Phone/RILJ RADIO_POWER=n (no second setRadioPower; -t80 on_true=n Complete=n; host radio SMS only)"
klog "m461 diag m460: persist ss set BEFORE start ril-daemon (setprop ss then stop then start; order ok)"
klog "m461 diag m460: airplane DID use --ez state true|false (am broadcast AIRPLANE_MODE); sequence was on then off"
klog "m461 diag m460: no num_rilds live / no WAITING_FOR_MULTIPLE_RILD_SYNC / no DMS GET after 19.375s"
klog "m350 persist no_wait_for_card=1 before rild"
klog "m380 skip nas_init wait — SET_UICC immediately"
klog "m381 skip nas_init wait"
klog "m383 skip nas_init wait"
klog "m396 skip nas_init wait — no Phone bind; grep CARDSTATE_PRESENT then SET_UICC"
klog "m398 remap unlocked PERSO->READY in vendor HIDL libril (not jar)"
klog "m392 skip nas_init wait — pidof + lshal then sleep 4 then grep -q CARDSTATE_PRESENT then SET_UICC"
klog "m380 do not hold Phone in a loop"
klog "m381 do not hold Phone in a loop"
klog "m383 do not hold Phone in a loop"
klog "m396 do not wait Phone bind in phase1"
klog "m396 do not wait RADIO_POWER complete in phase1"
klog "m383 wait CARDSTATE_PRESENT / USIM DETECTED before SET_UICC"
klog "m392 SET_UICC when this sit CARDSTATE_PRESENT via grep -q (no logcat-in-var)"
klog "m391 do not treat historical m383 card0 start-banner as current"
klog "m392 ignore stale m383 banners"
klog "m392 ignore first peek card=0"
klog "m390 do not use logcat -t 80 last-line compare"
klog "m392 after Phone bound sleep 4 then logcat -b radio -d | grep -q CARDSTATE_PRESENT"
klog "m396 grep CARDSTATE_PRESENT after IRadio (m392 pipe, no Phone bind)"
klog "m392 do not assign full logcat to a variable"
klog "m381 leftover tmp rm then vendor helper only"
klog "m387 persist.radio.multisim.config from first-stage /vendor/build.prop overlay (blob 0x79eab9 nas/uim init) — not late setprop, no UIM2"
klog "m395 two-phase: phase1 dsds (feature-2) then phase2 ss restart (num_rilds=1)"
if grep -q 'persist.radio.multisim.config=dsds' /vendor/build.prop 2>/dev/null; then
    klog "m387 /vendor/build.prop has persist.radio.multisim.config=dsds (first-stage bind)"
    klog "m395 /vendor/build.prop has persist.radio.multisim.config=dsds (first-stage bind; phase1)"
else
    klog "m387 /vendor/build.prop missing persist.radio.multisim.config=dsds"
    klog "m395 /vendor/build.prop missing persist.radio.multisim.config=dsds"
fi
setprop persist.radio.adb_log_on 1
setprop persist.radio.ril_payload_on 1
setprop persist.radio.no_wait_for_card 1
# m400 sit1: IOemHook 524325 parsed then "OEM HOOK RAW ... oem socket,
# not through rild socket" / socket not connected. Blob
# qmi_ril_is_feature_supported @ 0x137628 property_get
# persist.radio.oem_socket; false/0 disables that detour so rild
# dispatches QCRIL_EVT_HOOK_SET_PREFERRED_NETWORK_BAND_PREF.
setprop persist.radio.oem_socket 0
# m405: blob nas_init property_get persist.radio.force_nw_search @ 0x283444.
# 1 = enabled (strtoul 0/1 only). First-stage vendor/build.prop also 1.
# Clear leftover 0 so first property_get is 1. Not a new QMI client.
rm -f /data/property/persist.radio.force_nw_search
setprop persist.radio.force_nw_search 1
setprop sys.talkman.rild_wait 1
bind_vss_nv_stub
klog "m374 vss-nv stub bind early (post-fs-data)"

# m340: userdata is mounted (this oneshot starts on post-fs-data).
# Recover shipped qcril.db before rild. Same surviving path as this script
# (/debug_ramdisk/..., not /odm). Inline equivalent if first-stage did
# not stage the helper. Do not wipe userdata. Do not touch other /data.
run_qcril_recover() {
    DB=/data/misc/radio/qcril.db
    SRC=/system/etc/qcril.db
    mkdir -p /data/misc/radio 2>/dev/null
    need_recover=0
    if [ ! -f "$DB" ]; then
        need_recover=1
    else
        SQL=
        if [ -x /system/bin/sqlite3 ] && \
           /system/bin/sqlite3 "$SRC" "PRAGMA integrity_check;" >/dev/null 2>&1; then
            SQL=/system/bin/sqlite3
        elif [ -x /system/xbin/sqlite3 ] && \
             /system/xbin/sqlite3 "$SRC" "PRAGMA integrity_check;" >/dev/null 2>&1; then
            SQL=/system/xbin/sqlite3
        elif [ -x /vendor/bin/sqlite3 ] && \
             /vendor/bin/sqlite3 "$SRC" "PRAGMA integrity_check;" >/dev/null 2>&1; then
            SQL=/vendor/bin/sqlite3
        fi
        if [ -n "$SQL" ]; then
            ic=$($SQL "$DB" "PRAGMA integrity_check;" 2>/dev/null) || ic=
            ic=$(printf '%s\n' "$ic" | head -n 1 | tr -d '\r')
            [ "$ic" = "ok" ] || need_recover=1
        else
            hdr=$(head -c 15 "$DB" 2>/dev/null)
            if [ "$hdr" != "SQLite format 3" ]; then
                need_recover=1
            elif [ -e "${DB}-journal" ] || [ -e "${DB}-wal" ] || [ -e "${DB}-shm" ]; then
                need_recover=1
            fi
        fi
    fi
    if [ "$need_recover" = 1 ]; then
        rm -f "$DB" "${DB}-journal" "${DB}-wal" "${DB}-shm"
        if [ -f "$SRC" ] && cp "$SRC" "$DB"; then
            chown radio:radio "$DB" 2>/dev/null || chown radio.radio "$DB"
            chmod 660 "$DB"
            klog "m340 qcril-recover copied shipped db"
            setprop sys.talkman.qcril_recover 1
        else
            klog "m340 qcril-recover copy failed"
            setprop sys.talkman.qcril_recover 9
        fi
    else
        klog "m340 qcril-recover skip (userdata db ok)"
        setprop sys.talkman.qcril_recover 0
    fi
}
d=0
while [ "$d" -lt 40 ]; do
    [ -d /data ] && break
    sleep 0.25
    d=`expr $d + 1`
done
# m346: /debug_ramdisk recover.sh is gone after FreeRamdisk. Inline.
klog "m340 qcril-recover inline (m346 vendor-bind wait, no debug_ramdisk)"
run_qcril_recover

# 1) Wait until the sit hold node exists (device_initcall; do not invent paths).
w=0
while [ "$w" -lt 60 ]; do
    if [ -e "$STEP" ] && [ -e "$HOLD" ]; then
        klog "m338 auto-hold nodes STEP=$STEP HOLD=$HOLD"
        break
    fi
    sleep 0.5
    w=`expr $w + 1`
done
if [ ! -e "$STEP" ] || [ ! -e "$HOLD" ]; then
    klog "m338 auto-hold timeout: hold node missing — exit, no rild"
    setprop sys.talkman.rild_wait 9
    exit 0
fi

# 2) Wait-for-3: MBA STATUS=00000003 (META AUTH_SUCCESS / hold need=3).
#    If STATUS=00000004 already, auto-hold/AUTH already ran — skip echo 3.
ECHO3=n
ST4=n
mba=`read_mba`
case "$mba" in
    *STATUS=00000004*)
        klog "m338 auto-hold MBA already ST=4 — skip echo 3"
        ST4=y
        ;;
esac

if [ "$ST4" != y ]; then
    w=0
    while [ "$w" -lt 90 ]; do
        stop_rild_if_running
        mba=`read_mba`
        case "$mba" in
            *STATUS=00000004*)
                klog "m338 auto-hold MBA became ST=4 before echo 3 — skip echo 3"
                ST4=y
                break
                ;;
            *STATUS=00000003*)
                klog "m338 auto-hold MBA ST=3 after-META wait-for-3"
                break
                ;;
        esac
        sleep 0.5
        w=`expr $w + 1`
    done
    if [ "$ST4" != y ]; then
        case "$mba" in
            *STATUS=00000003*) ;;
            *)
                klog "m338 auto-hold timeout: no ST=3 — exit, no echo 3, no rild"
                setprop sys.talkman.rild_wait 9
                exit 0
                ;;
        esac
        # 3) echo 3 (never 2). Same path the sit writes.
        printf '3\n' > "$STEP"
        stepnow=`cat "$STEP" 2>/dev/null | tr -d '\r\n '`
        klog "m338 auto-hold echo 3 STEP=$stepnow"
        if [ "$stepnow" != 3 ]; then
            klog "m338 auto-hold echo 3 failed STEP=$stepnow — exit, never echo 2"
            setprop sys.talkman.rild_wait 9
            exit 0
        fi
        ECHO3=y
        setprop sys.talkman.hold3 1
    fi
fi

# 4) Wait ST=4 (AUTH_COMPLETE). Do not unhold without it.
if [ "$ST4" != y ]; then
    p=0
    while [ "$p" -lt 80 ]; do
        stop_rild_if_running
        mba=`read_mba`
        case "$mba" in
            *STATUS=00000004*)
                ST4=y
                klog "m338 auto-hold MBA ST=4 AUTH_COMPLETE"
                break
                ;;
        esac
        sleep 0.25
        p=`expr $p + 1`
    done
fi
if [ "$ST4" != y ]; then
    klog "m338 auto-hold timeout: no ST=4 — do not echo 0, no rild"
    setprop sys.talkman.rild_wait 9
    exit 0
fi
setprop sys.talkman.st4 1

# 5) echo 0 to talkman_hold (never 2). after-AUTH waits lab_hold==0.
holdnow=`cat "$HOLD" 2>/dev/null | tr -d '\r\n '`
if [ "$holdnow" != 0 ]; then
    printf '0\n' > "$HOLD"
    holdnow=`cat "$HOLD" 2>/dev/null | tr -d '\r\n '`
    klog "m338 auto-hold echo 0 HOLD=$holdnow"
else
    klog "m338 auto-hold HOLD already 0"
fi
if [ "$holdnow" != 0 ]; then
    klog "m338 auto-hold echo 0 failed HOLD=$holdnow — continue wait ONLINE anyway"
fi
setprop sys.talkman.hold0 1

# 6) Wait subsys3 ONLINE. Cap so boot UI/HWC is not blocked forever.
#    m380: do not hold Phone in a loop while waiting ONLINE.
ONLINE=n
er=0
while [ "$er" -lt 90 ]; do
    stop_rild_if_running
    st=`read_s3`
    if [ "$st" = ONLINE ]; then
        ONLINE=y
        klog "m338 auto-hold S3=ONLINE"
        break
    fi
    sleep 0.5
    er=`expr $er + 1`
done
if [ "$ONLINE" != y ]; then
    klog "m338 auto-hold timeout: S3=$(read_s3) not ONLINE — exit, no rild"
    setprop sys.talkman.rild_wait 9
    exit 0
fi
setprop sys.talkman.online 1

# Short wait for QMI_IPA_INIT in dmesg (m318). Not an invented sysfs.
q=0
while [ "$q" -lt 8 ]; do
    if dmesg 2>/dev/null | grep -q QMI_IPA_INIT; then
        klog "m338 auto-hold QMI_IPA_INIT"
        break
    fi
    sleep 0.25
    q=`expr $q + 1`
done

setprop persist.radio.adb_log_on 1
setprop persist.radio.ril_payload_on 1
setprop persist.radio.no_wait_for_card 1
setprop persist.radio.oem_socket 0
rm -f /data/property/persist.radio.force_nw_search
setprop persist.radio.force_nw_search 1
klog "m350 persist adb_log_on=$(getprop persist.radio.adb_log_on) no_wait_for_card=$(getprop persist.radio.no_wait_for_card)"
klog "m400 persist.radio.oem_socket=$(getprop persist.radio.oem_socket) (blob 0x137628; 0=rild OEM HOOK)"
klog "m405 persist.radio.force_nw_search=$(getprop persist.radio.force_nw_search) (blob nas_init 0x283444; 1→NAS FORCE_NETWORK_SEARCH 0x67)"
klog "m387 persist.radio.multisim.config=$(getprop persist.radio.multisim.config) at rild start (first-stage vendor/build.prop overlay, not late setprop)"
# m395 phase1 leftover-clear: m394 persist ss in /data would override
# vendor dsds. rm leftover file + setprop dsds BEFORE first ctl.start
# so first property_get @ 0x136cf0 fills cache=2 (dsds). Not after
# rild. Feature-2 ON for change_subscription. No UIM2.
rm -f /data/property/persist.radio.multisim.config
setprop persist.radio.multisim.config dsds
klog "m395 qmi_ril_retrieve_number_of_rilds @ 0x160ec0"
klog "m395 persist.radio.multisim.config=$(getprop persist.radio.multisim.config) before phase1 ril-daemon (dsds; feature-2; leftover ss cleared)"
klog "m395 blob property_get accepts dsds/dsda/tsts only (cache 2/4/3); else ss/ssss/empty → cache=1. No ssss token."
setprop sys.talkman.phase 1
bind_vss_nv_stub
klog "m374 vss-nv stub bind before rild"
bind_libril_remap
klog "m398 remap libril bind before rild"
# Real HIDL rild (device rild.legacy.rc). disabled + ctl.start is not a no-op.
# One ril-daemon only. Do not start a second radio / UIM2.
# m413 early KEYCODE_WAKEUP: as soon as this script can after ONLINE,
# before rild pid / RADIO_POWER / DMS ONLINE. One shot. Not a loop.
input keyevent 224
klog "m413 input keyevent 224 early (before first ril-daemon / rild pid; SCREEN_STATE enable=1)"
setprop sys.talkman.wakeup keyevent224
setprop ctl.start ril-daemon
klog "m338 auto-hold start ril-daemon after ONLINE"
klog "m346 IRadio start ril-daemon after ONLINE"
klog "m349 IRadio start ril-daemon only — Phone later"
klog "m350 IRadio start ril-daemon after ONLINE (no_wait=1)"
klog "m380 start ril-daemon after ONLINE — SET_UICC next, no Phone-hold"
setprop sys.talkman.rild_wait 2

# m411: rild pid only. Skip lshal — a full lshal each 0.3s delayed
# SET_UICC past the host USB race (m409 died su=7). Helper getService
# slot1 after PRESENT. Quiet. No Phone-hold.
ir=0
IRADIO_REG=n
while [ "$ir" -lt 40 ]; do
    rildpid=`pidof hw/rild 2>/dev/null`
    [ -z "$rildpid" ] && rildpid=`pidof rild 2>/dev/null`
    if [ -n "$rildpid" ]; then
        IRADIO_REG=y
        klog "m411 rild pid=$rildpid — skip lshal; PRESENT next"
        klog "m346 IRadio rild pid=$rildpid (no lshal)"
        klog "m413 rild pid=$rildpid after early keyevent 224 (no second early; not a loop)"
        klog "m415 rild pid=$rildpid — sleep 5 then one PRESENT grep (no 1s loop)"
        klog "m452 rild pid=$rildpid — sleep 5 then 4 spaced PRESENT greps over 20s (no 1s loop)"
        break
    fi
    sleep 0.25
    ir=`expr $ir + 1`
done
setprop sys.talkman.iradio_reg $IRADIO_REG
klog "m411 skip nas_init / PRL / Phone-hold / lshal — PRESENT then SET_UICC"
klog "m415 skip nas_init / PRL / Phone-hold / lshal — sleep 5 then one grep CARDSTATE_PRESENT then SET_UICC"
klog "m452 skip nas_init / PRL / Phone-hold / lshal — sleep 5 then 4 spaced greps CARDSTATE_PRESENT then SET_UICC once"
klog "m396 skip nas_init / PRL / Phone-hold — grep CARDSTATE_PRESENT then SET_UICC (no Phone bind)"
klog "m392 skip nas_init / PRL / Phone-hold — sleep 4 then grep -q CARDSTATE_PRESENT then SET_UICC"
klog "m380 skip nas_init / PRL / Phone-hold — wait PRESENT then SET_UICC"
klog "m383 skip nas_init / PRL / Phone-hold — wait PRESENT then SET_UICC"

# m381: leftover userdata helper is m349 setRadioPower only. Remove it.
# Exec ONLY the first-stage vendor bind (or /dev stage). Never tmp.
# Never extract base64 onto /data/local/tmp. Never host-push wait.
rm -f /data/local/tmp/talkman-iradio-on
klog "m381 rm leftover /data/local/tmp/talkman-iradio-on"
klog "m411 rm leftover /data/local/tmp/talkman-iradio-on — vendor helper only"
HELPER=""
for h in /vendor/bin/qmakernote-xtract /system/vendor/bin/qmakernote-xtract /dev/talkman-iradio-on; do
    if [ -x "$h" ]; then
        if grep -q setUiccSubscription "$h" 2>/dev/null; then
            HELPER=$h
            klog "m381 IRadio helper $HELPER (setUiccSubscription y)"
            klog "m383 IRadio helper $HELPER (setUiccSubscription y)"
            break
        else
            klog "m381 IRadio skip $h (no setUiccSubscription)"
        fi
    fi
done
if [ -z "$HELPER" ]; then
    klog "m381 IRadio vendor/dev helper missing — no leftover tmp"
fi

# m396 phase1 FAST: no Phone, no bind wait, no RADIO_POWER wait.
# Do not peek before SET_UICC (peek setResponseFunctions is the helper
# setuicc own-callback path). Gate is m392 pipe grep.
# Ignore first peek card=0. Ignore stale m383 banners.
mkdir -p /data/local/tmp 2>/dev/null
PEEK_CARD=0
PHONE_BOUND=n
setprop sys.talkman.phone_bound n
klog "m396 do not wait Phone bind in phase1"
klog "m396 do not wait RADIO_POWER complete in phase1"
klog "m349 IRadio true before Phone"
klog "m350 IRadio true before Phone"
klog "m392 ignore first peek card=0"
klog "m392 ignore stale m383 banners"
klog "m383 wait CARDSTATE_PRESENT / USIM DETECTED before SET_UICC"
klog "m392 after Phone bound sleep 4 then logcat -b radio -d | grep -q CARDSTATE_PRESENT"
klog "m396 grep CARDSTATE_PRESENT after IRadio (m392 pipe, no Phone bind)"
klog "m392 do not assign full logcat to a variable"
klog "m396 IRadio no Phone start before SET_UICC"
klog "m415 PRESENT sleep 5 then one logcat grep (no 1s loop; getprop gsm.sim.state UNKNOWN in phase1)"
klog "m452 PRESENT sleep 5 then 4 spaced greps over 20s (no 1s loop; SET_UICC once on PRESENT)"
PRESENT=n
USIM=n
CARD=0
uw=0
# m452: getprop gsm.sim.state is UNKNOWN in phase1 (m396/m398) so it
# cannot gate SET_UICC. qcril.db recover is not a card-state file.
# No UIM PRESENT sysfs in this tree. Do not invent QMI. Do not 1s-loop
# logcat (m411/m413 pumped USB/PS_HOLD). m415 sleep5+one-grep missed
# UIM PRESENT after 5s or a single grep miss (m450/m451 leftover=n
# PRESENT=timeout every sit). m396 with SIM in saw PRESENT ~5s.
# Four unrolled sleep-5 greps (5/10/15/20s). SET_UICC once if y.
# Timeout / SIM-out still phase2 ss (m439). USB death after ONLINE
# is non-HLOS PS_HOLD — spaced greps are not a TZ fix.
sleep 5
uw=5
if logcat -b radio -d 2>/dev/null | grep -q CARDSTATE_PRESENT; then
    PRESENT=y
    CARD=1
    klog "m452 this sit CARDSTATE_PRESENT waited=5s (spaced grep 1/4, no 1s loop, no var)"
    klog "m415 this sit CARDSTATE_PRESENT after sleep 5 (one grep -q, no loop, no var)"
    klog "m411 this sit CARDSTATE_PRESENT waited=5s (quiet one-grep, no 1s loop)"
    klog "m396 this sit CARDSTATE_PRESENT after sleep 5 (one grep -q, no Phone bind)"
else
    sleep 5
    uw=10
    if logcat -b radio -d 2>/dev/null | grep -q CARDSTATE_PRESENT; then
        PRESENT=y
        CARD=1
        klog "m452 this sit CARDSTATE_PRESENT waited=10s (spaced grep 2/4, no 1s loop, no var)"
    else
        sleep 5
        uw=15
        if logcat -b radio -d 2>/dev/null | grep -q CARDSTATE_PRESENT; then
            PRESENT=y
            CARD=1
            klog "m452 this sit CARDSTATE_PRESENT waited=15s (spaced grep 3/4, no 1s loop, no var)"
        else
            sleep 5
            uw=20
            if logcat -b radio -d 2>/dev/null | grep -q CARDSTATE_PRESENT; then
                PRESENT=y
                CARD=1
                klog "m452 this sit CARDSTATE_PRESENT waited=20s (spaced grep 4/4, no 1s loop, no var)"
            else
                PRESENT=timeout
                CARD=0
                klog "m452 this sit PRESENT timeout=20s — no SET_UICC; phase2 still (4 spaced greps miss; no 1s loop)"
                klog "m415 this sit PRESENT timeout=20s — no SET_UICC; phase2 still (spaced greps miss; no loop)"
                klog "m439 this sit PRESENT timeout=20s — skip SET_UICC; still phase2 ss (SIM out / ABSENT / miss)"
                klog "m411 this sit PRESENT timeout=20s card=0 (quiet; no 1s loop)"
                klog "m396 this sit PRESENT timeout=20s (no Phone bind; no SET_UICC; phase2 still)"
            fi
        fi
    fi
fi
klog "m452 this sit PRESENT=$PRESENT card=$CARD waited=$uw (sleep5+4spaced-greps20s, no host SET_UICC)"
klog "m415 this sit PRESENT=$PRESENT card=$CARD waited=$uw (sleep5+one-logcat, no host SET_UICC)"
klog "m411 this sit PRESENT=$PRESENT card=$CARD waited=$uw (no Phone bind, no host SET_UICC)"
klog "m392 this sit PRESENT=$PRESENT peek_card=$PEEK_CARD card=$CARD waited=$uw phone_bound=$PHONE_BOUND (grep -q, no var)"
klog "m396 this sit PRESENT=$PRESENT card=$CARD waited=$uw (no Phone bind)"
setprop sys.talkman.uim_present $PRESENT
setprop sys.talkman.usim $USIM
setprop sys.talkman.card $CARD
setprop sys.talkman.peek_card $PEEK_CARD

SET_UICC=n
SET_UICC_RC=n
SET_UICC_AFTER_PRESENT=n
if [ -z "$HELPER" ]; then
    klog "m383 IRadio setUicc helper missing"
    setprop sys.talkman.set_uicc_rc 9
    setprop sys.talkman.set_uicc n
    setprop sys.talkman.set_uicc_after_present n
elif [ "$PRESENT" = y ]; then
    CARD=1
    klog "m383 IRadio setUiccSubscription run $HELPER setuicc after PRESENT"
    klog "m381 IRadio setUiccSubscription run $HELPER setuicc"
    klog "m392 IRadio setUiccSubscription after Phone bound + grep -q CARDSTATE_PRESENT"
    klog "m396 IRadio setUiccSubscription after grep -q CARDSTATE_PRESENT (no Phone bind)"
    klog "m411 IRadio setUiccSubscription once after PRESENT (own callbacks, no host)"
    klog "m415 IRadio setUiccSubscription once after sleep5+one-logcat PRESENT=$PRESENT (own callbacks, no host)"
    klog "m452 IRadio setUiccSubscription once after spaced PRESENT=$PRESENT waited=$uw (own callbacks, no host)"
    klog "m439 IRadio setUiccSubscription once only because PRESENT=y (not timeout/ABSENT)"
    SET_UICC_AFTER_PRESENT=y
    setprop sys.talkman.set_uicc_after_present y
    setprop sys.talkman.card 1
    # m457: helper is blocking. HIDL error is set_uicc_err (rc=0
    # only means the response callback arrived). Clear leftover
    # err, then wait for the process. Do not background setuicc.
    setprop sys.talkman.set_uicc_err none
    "$HELPER" setuicc
    SET_UICC_RC=$?
    SET_UICC_ERR=`getprop sys.talkman.set_uicc_err`
    klog "m383 IRadio setUicc helper rc=$SET_UICC_RC path=$HELPER"
    klog "m392 IRadio setUicc helper rc=$SET_UICC_RC path=$HELPER"
    klog "m396 IRadio setUicc helper rc=$SET_UICC_RC path=$HELPER"
    klog "m457 IRadio setUicc helper rc=$SET_UICC_RC err=$SET_UICC_ERR path=$HELPER (sync; set_uicc=y only rc=0 err=0)"
    setprop sys.talkman.set_uicc_rc $SET_UICC_RC
    setprop sys.talkman.helper_path "$HELPER"
    # m457: leftover done files are not this-sit HIDL error 0.
    # Helper property_set(set_uicc_err) is often invisible (m457
    # sit: HIDL error=0 in kmsg, getprop still leftover none).
    # rc=0 means the HIDL callback arrived. Treat none/empty/0
    # as error 0. Numeric non-zero is a real HIDL error.
    if [ "$SET_UICC_RC" = 0 ]; then
        case "$SET_UICC_ERR" in
            0|none|'')
                SET_UICC=y
                klog "m383 IRadio SET_UICC sent after PRESENT"
                klog "m392 IRadio SET_UICC issued"
                klog "m396 IRadio SET_UICC issued"
                klog "m411 IRadio SET_UICC issued (one shot, no host)"
                klog "m415 IRadio SET_UICC issued (one shot after quiet PRESENT, no host)"
                klog "m452 IRadio SET_UICC issued (one shot after spaced PRESENT, no host)"
                klog "m457 IRadio SET_UICC issued (sync helper rc=0 err=$SET_UICC_ERR; phase2 next)"
                klog "m458 IRadio SET_UICC issued (sync helper rc=0 err=$SET_UICC_ERR treated as 0; 1s GW then phase2)"
                klog "m460 IRadio SET_UICC issued (sync helper rc=0 err=$SET_UICC_ERR treated as 0; drop GW; immediate phase2)"
                ;;
            *)
                SET_UICC=n
                klog "m457 SET_UICC=n rc=0 HIDL err=$SET_UICC_ERR — still phase2 ss"
                klog "m439 SET_UICC rc=0 err=$SET_UICC_ERR — still phase2 ss (do not skip)"
                ;;
        esac
    elif [ "$SET_UICC_RC" = 8 ]; then
        SET_UICC=n
        SET_UICC_AFTER_PRESENT=n
        klog "m383 do not setuicc on card=0 (helper refused)"
        klog "m392 this sit helper refused card0 after PRESENT"
        klog "m396 this sit helper refused card0 after PRESENT"
        klog "m439 SET_UICC rc=8 — still phase2 ss (do not skip)"
        klog "m457 SET_UICC=n rc=8 — still phase2 ss (do not skip)"
        setprop sys.talkman.set_uicc_after_present n
    else
        SET_UICC=n
        klog "m457 SET_UICC=n rc=$SET_UICC_RC err=$SET_UICC_ERR — not HIDL error 0; still phase2 ss"
        klog "m439 SET_UICC rc=$SET_UICC_RC — still phase2 ss (do not skip)"
    fi
else
    klog "m415 this sit do not setuicc — helper/card gate miss (sleep5+one-logcat already ran)"
    klog "m452 this sit do not setuicc — PRESENT=$PRESENT waited=$uw (4 spaced greps; still phase2 ss)"
    klog "m411 this sit do not setuicc — no CARDSTATE_PRESENT in quiet PRESENT"
    klog "m392 this sit do not setuicc — no CARDSTATE_PRESENT in sleep4+12s grep -q"
    klog "m396 this sit do not setuicc — no CARDSTATE_PRESENT"
    klog "m439 this sit do not setuicc — PRESENT=$PRESENT (timeout/ABSENT); still phase2 ss"
    setprop sys.talkman.set_uicc_rc 8
    setprop sys.talkman.set_uicc n
    setprop sys.talkman.set_uicc_after_present n
    setprop sys.talkman.helper_path "$HELPER"
fi
setprop sys.talkman.set_uicc $SET_UICC
setprop sys.talkman.set_uicc_after_present $SET_UICC_AFTER_PRESENT
# m467: SET_UICC helper already returned. Confirm process
# exit (release IRadio). Do not keep helper as client.
HELPER_ALIVE=`pidof qmakernote-xtract 2>/dev/null`
klog "m467 SET_UICC helper exit pid=$HELPER_ALIVE (empty=released IRadio; not holding callbacks)"
if [ -n "$HELPER_ALIVE" ]; then
    sleep 1
    HELPER_ALIVE=`pidof qmakernote-xtract 2>/dev/null`
    klog "m467 SET_UICC helper settle pid=$HELPER_ALIVE (empty=dead; phase2 next)"
fi

# m439: always phase2 ss + stop/start ril-daemon.
# m460: drop the two GW greps. m459 proved GW never 0x0 after
# SET_UICC in this window; those greps (sleep 1 + dump +
# sleep 1) started phase2 at ~22.2s and the +16s host dump
# caught mid rild restart — air_retry had not run. Immediate
# phase2 so airplane off→on→off finishes before ~kernel 24s.
# Score GW in the one-shot post-air-retry dump. PRESENT
# timeout / SET_UICC fail / ABSENT: still phase2 (m439).
# Do not skip phase2. Do not wipe provision. No host SET_UICC.
# Do not steal IRadio after Phone bind. Not a 1s logcat loop.
GW0=n
GSM0=n
P1_RP=n
P1_RP_COMP=n
if [ "$SET_UICC" = y ]; then
    klog "m460 drop phase1 GW greps after SET_UICC — m459 never 0x0; immediate phase2 (air_retry before dump)"
    klog "m415 phase1 GW sleep 1 then phase2 (no logcat loop; m396 GW waited=0 after SET_UICC)"
    klog "m411 phase1 wait GW after SET_UICC (dsds feature-2; no Phone; no logcat loop)"
    setprop sys.talkman.phase 1
    setprop sys.talkman.gw0 $GW0
    setprop sys.talkman.gsm0 $GSM0
    setprop sys.talkman.p1_rp $P1_RP
    setprop sys.talkman.p1_rp_comp $P1_RP_COMP
else
    klog "m439 phase2 anyway — PRESENT=$PRESENT SET_UICC=$SET_UICC rc=$SET_UICC_RC (timeout/fail/ABSENT; do not skip)"
    klog "m460 phase2 anyway — PRESENT=$PRESENT SET_UICC=$SET_UICC (no GW wait; air_retry still)"
    setprop sys.talkman.phase 1
    setprop sys.talkman.gw0 $GW0
    setprop sys.talkman.gsm0 $GSM0
    setprop sys.talkman.p1_rp $P1_RP
    setprop sys.talkman.p1_rp_comp $P1_RP_COMP
fi
klog "m439 phase2 persist ss then stop/start ril-daemon (num_rilds=1; timeout/fail/ABSENT still)"
klog "m460 phase2 persist ss then stop/start ril-daemon immediately (no GW wait; air_retry next)"
klog "m461 phase2 setprop ss THEN stop THEN start ril-daemon (never start before ss)"
klog "m411 phase2 persist ss then stop/start ril-daemon immediately (num_rilds=1; keep GW; no host)"
klog "m396 phase2 persist ss then stop/start ril-daemon immediately (num_rilds=1; keep GW)"
klog "m395 phase2 persist ss then stop/start ril-daemon (num_rilds=1; keep GW)"
setprop persist.radio.multisim.config ss
klog "m396 persist.radio.multisim.config=$(getprop persist.radio.multisim.config) before phase2 ril-daemon (ss; blob else→cache=1; not dsds/dsda/tsts)"
klog "m395 persist.radio.multisim.config=$(getprop persist.radio.multisim.config) before phase2 ril-daemon (ss; blob else→cache=1; not dsds/dsda/tsts)"
klog "m395 do not wipe provision — MPSS keep GW"
klog "m396 do not wipe provision — MPSS keep GW"
setprop sys.talkman.phase 2
setprop sys.talkman.phase2_persist ss
# m509 Phone-first wait: persist props for the new ss process,
# then drop phase1 IRadio before Phone starts. RILJ
# getService("slot1", true) waits; it does not poll a live
# phase1 client.
setprop persist.radio.lte_full_band 0xa0080908df
setprop persist.radio.oem_socket 0
setprop persist.radio.force_nw_search 1
klog "m400 persist.radio.lte_full_band=0xa0080908df (blob nas_init 0x28c528; modem mask m399)"
klog "m400 persist.radio.oem_socket=0 (blob 0x137628; false/0 → oem socket off)"
klog "m405 persist.radio.force_nw_search=1 (blob nas_init 0x283444; 1=enabled; phase2 rild re-reads)"
klog "m400 skip IOemHook SET_PREFERRED_NETWORK_BAND_PREF — sit1 oem-socket-only; do not retry IOemHook"
PHONE_REBIND=n
HELPER_RP=n
HELPER_RP_COMP=n
HELPER_RP_RC=n
POST_GET0=n
POST_OPRT=n
POST_RP=n
AIR_RETRY=n
PHONE_API=n
PHONE_BOUND=n
BIND_SEEN=n
PRE_SRF=0
POST_SRF=0
SST=unknown
RADIO_STATE=none
TXN=18
SC1=none
NAS67=n
ISO=n
FNWS=n
setprop sys.talkman.post_get0 n
setprop sys.talkman.post_oprt n
setprop sys.talkman.post_rp n
setprop sys.talkman.air_retry n
setprop sys.talkman.helper_rp n
setprop sys.talkman.helper_rp_comp n
setprop sys.talkman.helper_rp_err none
setprop sys.talkman.helper_rp_rc n
# m509: stop phase1 rild BEFORE Phone so persist=ss cannot
# bind the dying IRadio (false m474 non-null ss) and so
# getService(slot1, true) waits for the ss process.
klog "m509 phase2 stop ril-daemon before Phone (IRadio down; getService will wait)"
stop ril-daemon
st=0
while [ "$st" -lt 20 ]; do
    ril=`getprop init.svc.ril-daemon`
    if [ "$ril" != running ]; then
        klog "m509 phase2 ril-daemon stopped svc=$ril before Phone"
        klog "m396 phase2 ril-daemon stopped svc=$ril"
        klog "m395 phase2 ril-daemon stopped svc=$ril"
        break
    fi
    sleep 0.25
    st=`expr $st + 1`
done
sleep 1
# force-stop then start Phone while IRadio is down. Do not
# wait pid empty (m482 sit1/3 dumped in that wait).
am force-stop com.android.phone
PHONE_REBIND=y
klog "m509 phone_rebind force-stop then start Phone while IRadio down (getService waits; no pid-empty wait)"
klog "m489 phone_rebind force-stop then start Phone then ss rild (Phone-first; RILJ getService will retry; no pid-empty wait)"
klog "m485 phone_rebind force-stop com.android.phone (sleep 1 then helper setRadioPower; do not wait pid empty)"
klog "m484 phone_rebind force-stop com.android.phone (sleep 1 then helper setRadioPower; do not wait pid empty)"
klog "m483 phone_rebind force-stop com.android.phone (sleep 1 then helper setRadioPower; do not wait pid empty)"
klog "m482 phone_rebind force-stop com.android.phone (helper setRadioPower next; Phone down; wait pid empty before power)"
klog "m474 phone_rebind force-stop com.android.phone (fresh RILJ on ss rild; wait pid empty before start)"
klog "m473 phone_rebind force-stop com.android.phone (fresh RILJ on ss rild; Phone-owned RADIO_POWER next; no helper power)"
klog "m471 phone_rebind force-stop com.android.phone (helper setRadioPower next; Phone not bound)"
klog "m469 phone_rebind force-stop com.android.phone (helper setRadioPower next; Phone not bound)"
klog "m461 phone_rebind force-stop com.android.phone (fresh RADIO_POWER on ss rild; not IRadio steal)"
klog "m462 phone_down force-stop com.android.phone (helper setRadioPower next; Phone not bound)"
setprop sys.talkman.phone_bound n
setprop sys.talkman.phone_rebind y
klog "m396 pm enable com.android.phone after phase2"
klog "m381 pm enable com.android.phone once"
klog "m380 pm enable com.android.phone once"
klog "m383 pm enable com.android.phone once"
pm enable --user 0 com.android.phone >/dev/null 2>&1
setprop sys.talkman.phone_disabled 0
am start -n com.android.phone/.PhoneApp >/dev/null 2>&1
setprop ctl.start com.android.phone
setprop sys.talkman.phone_rebind y
klog "m509 Phone-first start com.android.phone while IRadio down (getService slot1 true waits)"
klog "m489 Phone-first start com.android.phone before ss rild (RILJ getService will retry)"
# m485 post-helper stop ril-daemon (fresh IRadio; GET 0 may drop)
# m485 post-helper start ril-daemon (never-helper-touched IRadio; Phone txn 18 must re-ONLINE)
# m483 sleep 1 after force-stop — helper setRadioPower next (no pid-empty wait)
klog "m483 sleep 1 after force-stop — helper setRadioPower next (no pid-empty wait)"
klog "m485 Phone start after fresh ril-daemon — leftover air then sleep 3 then txn 18 (never-helper-touched IRadio; GET 0 may drop; no pid-empty wait; no bind logcat)"
klog "m484 Phone start after helper setResponseFunctions(null)+exit — leftover air then sleep 2 then txn 18 (no pid-empty wait; no bind logcat)"
klog "m483 Phone start after helper setResponseFunctions(null)+exit — leftover air then sleep 2 then txn 18 (no pid-empty wait; no bind logcat)"
klog "m482 Phone start after helper setResponseFunctions(null)+exit — wait pid then sleep 3 then leftover air then txn 18 (no bind logcat)"
klog "m474 Phone start after force-stop — leftover air done; wait pid then sleep 3 then txn 18 (no helper power; no bind logcat)"
klog "m473 Phone start after force-stop — leftover air done; sleep 3 then txn 18 (no helper power; no bind logcat)"
klog "m471 Phone start after helper setResponseFunctions(null)+exit — sleep 2 then txn 18 (no bind logcat)"
klog "m461 phone_rebind start com.android.phone after force-stop"
klog "m338 auto-hold start com.android.phone"
klog "m346 IRadio start com.android.phone keep"
klog "m346 stock jar start com.android.phone once"
klog "m396 IRadio start com.android.phone after phase2"
klog "m398 do not SET_UICC after phase2 — keep Phone indications"
klog "m398 do not peek/setuicc after Phone bind"
klog "m489 do not take IRadio after Phone bind — ss rild next then leftover air then sleep 2 then ITelephony txn=18 i32 1"
klog "m483 do not take IRadio after Phone bind — leftover air then sleep 2 then ITelephony txn=18 i32 1"
klog "m482 do not take IRadio after Phone bind — sleep 3 then leftover air then ITelephony txn=18 i32 1"
klog "m474 do not take IRadio after Phone bind — sleep 3 then ITelephony txn=18 i32 1"
klog "m473 do not take IRadio after Phone bind — sleep 3 then ITelephony txn=18 i32 1"
setprop sys.talkman.phone 1
setprop sys.talkman.phone_held 0
setprop sys.talkman.iradio_helper none
setprop sys.talkman.iradio_on 0
setprop sys.talkman.iradio_reply n
setprop sys.talkman.dms_left n
setprop sys.talkman.nas_init skip
setprop sys.talkman.prl_done skip
setprop sys.talkman.prl_deq skip
setprop sys.talkman.prl_cap skip
setprop sys.talkman.rild_wait 3
phpid=`pidof com.android.phone 2>/dev/null`
klog "m509 Phone pid=$phpid after start — start ss ril-daemon next (getService wait; no pid-empty wait)"
klog "m489 Phone pid=$phpid after start — stop/start ril-daemon next (IRadio appears while Phone polling; no pid-empty wait)"
klog "m485 Phone pid=$phpid after start — leftover air getprop once then sleep 3 (fresh IRadio; no pid-empty wait; no bind logcat greps; no IRadio steal)"
klog "m483 Phone pid=$phpid after start — leftover air getprop once then sleep 2 (no pid-empty wait; no bind logcat greps; no IRadio steal)"
klog "m482 Phone pid=$phpid after start waited=$pw — sleep 3 (no bind logcat greps; no IRadio steal)"
klog "m474 Phone pid=$phpid after start waited=$pw — sleep 3 (no bind logcat greps; no IRadio steal)"
klog "m473 Phone pid=$phpid after start — sleep 3 (no bind logcat greps; no IRadio steal)"
# bind=y only a NEW m474 non-null ss after this start (not a
# persist=ss klog on the dying phase1 process).
PRE_SRF=`dmesg 2>/dev/null | grep -c 'm474 setResponseFunctions non-null ss'`
[ -z "$PRE_SRF" ] && PRE_SRF=0
start ril-daemon
klog "m509 phase2 start ril-daemon after Phone-first wait (ss; getService unblocks; pre_srf=$PRE_SRF)"
klog "m489 phase2 start ril-daemon after Phone start (ss; Phone already polling)"
klog "m396 phase2 start ril-daemon ss num_rilds=1 first property_get"
klog "m395 phase2 start ril-daemon ss num_rilds=1 first property_get"
klog "m411 phase2 start ril-daemon ss num_rilds=1 first property_get (auto, no host)"
klog "m439 phase2 start ril-daemon ss num_rilds=1 (always; not gated on SET_UICC)"
klog "m461 phase2 start ril-daemon after persist ss (ss-before-start; new process re-reads num_rilds)"
# m413: one more KEYCODE_WAKEUP after phase2 rild restart. Not a loop.
# Do not steal IRadio. No dumpsys. No host SET_UICC.
input keyevent 224
klog "m413 input keyevent 224 after phase2 ril-daemon restart (SCREEN_STATE enable=1 before Phone RADIO_POWER)"
setprop sys.talkman.wakeup keyevent224
setprop sys.talkman.phase2 y
pr=0
while [ "$pr" -lt 8 ]; do
    rildpid=`pidof hw/rild 2>/dev/null`
    [ -z "$rildpid" ] && rildpid=`pidof rild 2>/dev/null`
    if [ -n "$rildpid" ]; then
        klog "m509 phase2 rild pid=$rildpid after Phone-first wait — leftover air then sleep 2 then txn 18 (no helper if Phone up; no bind logcat)"
        klog "m489 phase2 rild pid=$rildpid after Phone-first — leftover air then sleep 2 then txn 18 (helper only if unbound; no bind logcat)"
        klog "m485 phase2 rild pid=$rildpid after ss — force-stop then sleep 1 then helper power then release then stop/start ril-daemon then start Phone then leftover air then sleep 3 then txn 18 (fresh IRadio; GET 0 may drop; Phone txn 18 re-ONLINE; no bind logcat)"
        klog "m484 phase2 rild pid=$rildpid after ss — force-stop then sleep 1 then helper power then release then start Phone then leftover air then sleep 2 then txn 18 (no pid-empty wait; keep death cookie; GET 0 from helper SET ONLINE operating mode 0; no bind logcat)"
        klog "m483 phase2 rild pid=$rildpid after ss — force-stop then sleep 1 then helper power then release then start Phone then leftover air then sleep 2 then txn 18 (no pid-empty wait; death cookie; GET 0 + Phone IRadio; no bind logcat)"
        klog "m482 phase2 rild pid=$rildpid after ss — force-stop then helper power then release then wait pid-empty then sleep 3 then leftover air then txn 18 (death cookie; GET 0 + Phone IRadio; no bind logcat)"
        klog "m474 phase2 rild pid=$rildpid after ss — force-stop wait-pid-empty then leftover air then sleep 3 then txn 18 (Phone-owned; no helper power; no bind logcat)"
        klog "m473 phase2 rild pid=$rildpid after ss — force-stop then leftover air then sleep 3 then txn 18 (Phone-owned; no helper power; no bind logcat)"
        klog "m471 phase2 rild pid=$rildpid after ss — force-stop then helper power then release then sleep 2 then txn 18 (no bind logcat)"
        klog "m469 phase2 rild pid=$rildpid after ss — force-stop then helper power then Phone bind (no settings stall)"
        klog "m461 phase2 rild pid=$rildpid after ss — phone_rebind next"
        klog "m462 phase2 rild pid=$rildpid after ss — force-stop then helper power"
        break
    fi
    sleep 0.25
    pr=`expr $pr + 1`
done
klog "m346 IRadio bound=$PHONE_BOUND reg=$IRADIO_REG"
klog "m452 SET_UICC=$SET_UICC after_present=$SET_UICC_AFTER_PRESENT rc=$SET_UICC_RC present=$PRESENT card=$CARD waited=$uw phase2=$(getprop sys.talkman.phase2)"
klog "m411 SET_UICC=$SET_UICC after_present=$SET_UICC_AFTER_PRESENT rc=$SET_UICC_RC present=$PRESENT card=$CARD phone_bound=$PHONE_BOUND phase2=$(getprop sys.talkman.phase2)"
klog "m396 SET_UICC=$SET_UICC after_present=$SET_UICC_AFTER_PRESENT rc=$SET_UICC_RC present=$PRESENT card=$CARD phone_bound=$PHONE_BOUND phase2=$(getprop sys.talkman.phase2)"
klog "m392 SET_UICC=$SET_UICC after_present=$SET_UICC_AFTER_PRESENT rc=$SET_UICC_RC present=$PRESENT peek=$PEEK_CARD card=$CARD phone_bound=$PHONE_BOUND"
klog "m457 SET_UICC=$SET_UICC after_present=$SET_UICC_AFTER_PRESENT rc=$SET_UICC_RC err=$(getprop sys.talkman.set_uicc_err) present=$PRESENT card=$CARD phase2=$(getprop sys.talkman.phase2)"
# leftover airplane AFTER Phone start + ss rild, BEFORE sleep 2.
# getprop persist.radio.airplane_mode_on once. Do not settings get
# (m467 burned ~5s). Only broadcast if 1. Never airplane persist
# as a fake camp. Never leave airplane on.
AIRPLANE=`getprop persist.radio.airplane_mode_on | tr -d '\r'`
klog "m489 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once after Phone-first ss rild; no settings stall)"
klog "m485 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once after Phone start; no settings stall)"
klog "m484 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once after Phone start; no settings stall)"
klog "m483 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once after Phone start; no settings stall)"
klog "m482 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once after sleep 3; no settings stall)"
klog "m474 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once; no settings stall)"
klog "m473 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once; no settings stall)"
klog "m471 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once; no settings stall)"
klog "m469 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once; no settings stall)"
klog "m468 leftover persist.radio.airplane_mode_on=$AIRPLANE (getprop once; no settings stall)"
klog "m467 leftover airplane_mode_on=$AIRPLANE (userdata persist; 1to0 only if 1)"
klog "m464 leftover airplane_mode_on=$AIRPLANE (userdata persist; before Phone start)"
[ -z "$AIRPLANE" ] && AIRPLANE=0
setprop sys.talkman.airplane "$AIRPLANE"
if [ "$AIRPLANE" = 1 ]; then
    settings put global airplane_mode_on 0
    am broadcast -a android.intent.action.AIRPLANE_MODE --ez state false
    klog "m489 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m485 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m483 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m482 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m474 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m473 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m471 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m469 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m468 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m467 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false"
    klog "m464 leftover airplane was 1 — set 0 + AIRPLANE_MODE --ez state false before Phone"
    AIRPLANE=0
    setprop sys.talkman.airplane 0
    setprop sys.talkman.air_leftover y
else
    klog "m489 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m485 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m484 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m483 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m482 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m474 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m473 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m471 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m469 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m468 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m467 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    klog "m464 leftover airplane not 1 (value=$AIRPLANE) — no leftover air broadcast"
    setprop sys.talkman.air_leftover n
fi
# sleep 2 for Phone to bind the new IRadio. Do NOT logcat
# bind greps (m469/m470 USB/PS_HOLD suspect). bind=y only
# a NEW m474 setResponseFunctions non-null ss after ss
# rild start. Do not take IRadio after Phone is up.
sleep 2
# cheap IRadio: one dmesg awk (full lshal is not cheap).
bindflags=`dmesg 2>/dev/null | awk '
BEGIN { srf="n"; rr="n"; rilj="n"; rsvc="n"; rimpl="n"; ir="n" }
index($0, "setResponseFunctions non-null") { srf="y" }
index($0, "m474 setResponseFunctions non-null ss") { srf="y" }
index($0, "mRadioResponse non-NULL") { rr="y" }
index($0, "mRadioResponse non-null") { rr="y" }
index($0, "mRadioResponse != NULL") { rr="y" }
index($0, "RadioResponse registered") { rr="y" }
index($0, "RILJ") { rilj="y" }
index($0, "RadioService") { rsvc="y" }
index($0, "RadioImpl") { rimpl="y" }
index($0, "android.hardware.radio@") { ir="y" }
END { printf "srf=%s rr=%s rilj=%s rsvc=%s rimpl=%s ir=%s\n", srf, rr, rilj, rsvc, rimpl, ir }
'`
POST_SRF=`dmesg 2>/dev/null | grep -c 'm474 setResponseFunctions non-null ss'`
[ -z "$POST_SRF" ] && POST_SRF=0
klog "m509 one-shot dmesg pre_srf=$PRE_SRF post_srf=$POST_SRF $bindflags (bind only new non-null ss)"
klog "m489 one-shot dmesg $bindflags (lshal skip not cheap; bind only srf/rr registered — not missing)"
klog "m485 one-shot dmesg $bindflags (lshal skip not cheap; bind only srf/rr registered — not missing)"
if [ "$POST_SRF" -gt "$PRE_SRF" ]; then
    PHONE_BOUND=y
    BIND_SEEN=y
    klog "m509 Phone setResponseFunctions non-null ss after ss rild (bind=y; skip helper)"
    klog "m489 Phone setResponseFunctions or RadioResponse registered (bind=y; skip helper)"
    klog "m485 Phone setResponseFunctions or RadioResponse registered (bind=y)"
    klog "m474 Phone setResponseFunctions non-null ss in kmsg (libril cookie live)"
else
    klog "m509 Phone setResponseFunctions non-null ss not new after ss rild (pre=$PRE_SRF post=$POST_SRF) — still txn 18; no helper"
    klog "m489 Phone setResponseFunctions/RadioResponse not registered after 2s"
    klog "m474 Phone setResponseFunctions non-null ss missing in kmsg — still txn 18"
fi
phpid=`pidof com.android.phone 2>/dev/null`
if [ "$PHONE_BOUND" = y ] || [ "$BIND_SEEN" = y ]; then
    klog "m489 skip helper — Phone already bound (do not steal IRadio)"
    klog "m489 prefer no helper IRadio if Phone is up"
elif [ -z "$phpid" ]; then
    klog "m489 skip helper — Phone down"
else
    klog "m509 skip helper — Phone up unbound; getService wait should bind; helper would steal IRadio"
    klog "m489 prefer no helper IRadio if Phone is up"
    HELPER_RP=n
    HELPER_RP_COMP=n
    HELPER_RP_RC=n
fi
setprop sys.talkman.helper_rp $HELPER_RP
setprop sys.talkman.helper_rp_comp $HELPER_RP_COMP
setprop sys.talkman.helper_rp_rc $HELPER_RP_RC
klog "m509 sleep 2 done — ITelephony.setRadioPower txn=18 i32 1; Phone-first wait; no helper if Phone up"
klog "m489 sleep 2 done — ITelephony.setRadioPower txn=18 i32 1; Phone-first; helper only if unbound"
klog "m485 sleep 3 done — ITelephony.setRadioPower txn=18 i32 1; helper dead; fresh rild; Phone had 3s to bind"
klog "m484 sleep 2 done — ITelephony.setRadioPower txn=18 i32 1; helper dead; Phone had 2s to bind"
klog "m483 sleep 2 done — ITelephony.setRadioPower txn=18 i32 1; helper dead; Phone had 2s to bind"
klog "m482 sleep 3 done — leftover air getprop once then ITelephony.setRadioPower txn=18 i32 1; helper dead; Phone had 3s to bind"
klog "m474 sleep 3 done — ITelephony.setRadioPower txn=18 i32 1 from ITelephony.aidl method 18; Phone had 3s to bind; no helper power"
klog "m473 sleep 3 done — ITelephony.setRadioPower txn=18 i32 1 from ITelephony.aidl method 18; Phone had 3s to bind; no helper power"
klog "m466 ITelephony.setRadioPower txn=18 from ITelephony.aidl method 18 setRadioPower(boolean); setRadio=16; cmd phone has no radio-power"
SC1=`service call phone 18 i32 1 2>&1 | tr '\n' ' ' | tr -d '\r'`
klog "m489 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m485 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m484 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m483 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m482 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m474 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m473 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m471 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m469 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m468 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m467 ITelephony.setRadioPower(true) txn=18 $SC1"
klog "m466 ITelephony.setRadioPower(true) txn=18 $SC1"
PHONE_API=y
TXN=18
setprop sys.talkman.phone_api y
setprop sys.talkman.phone_api_txn 18
setprop sys.talkman.txn18 y
setprop sys.talkman.sst $SST
setprop sys.talkman.phone_bound $PHONE_BOUND
setprop sys.talkman.radio_state "$RADIO_STATE"
klog "m489 txn18=y txn=$TXN reply=$SC1 sst=$SST sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.numeric) helper_rp=$HELPER_RP bind=$BIND_SEEN phone_bound=$PHONE_BOUND"
klog "m485 txn18=y txn=$TXN reply=$SC1 sst=$SST sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.numeric) helper_rp=$HELPER_RP bind=$BIND_SEEN phone_bound=$PHONE_BOUND"
klog "m484 txn18=y txn=$TXN reply=$SC1 sst=$SST sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.numeric) helper_rp=$HELPER_RP bind=$BIND_SEEN phone_bound=$PHONE_BOUND"
klog "m483 txn18=y txn=$TXN reply=$SC1 sst=$SST sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.numeric) helper_rp=$HELPER_RP bind=$BIND_SEEN phone_bound=$PHONE_BOUND"
klog "m482 txn18=y txn=$TXN reply=$SC1 sst=$SST sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.numeric) helper_rp=$HELPER_RP bind=$BIND_SEEN phone_bound=$PHONE_BOUND"
klog "m474 txn18=y txn=$TXN reply=$SC1 sst=$SST sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.numeric) helper_rp=n bind=$BIND_SEEN phone_bound=$PHONE_BOUND"
klog "m473 txn18=y txn=$TXN reply=$SC1 sst=$SST sim=$(getprop gsm.sim.state) op=$(getprop gsm.sim.operator.numeric) helper_rp=n"
# m511: one second for DMS GET 0 to land in radio before the
# one-shot score gates the post-GET0 SCREEN_STATE keyevent.
# Not a loop. Not a logcat wait. Do not send 0x67.
klog "m511 sleep 1 after txn 18 for DMS GET 0 before SCREEN_STATE (not a loop; do not send 0x67)"
sleep 1

# one-shot kmsg scores: one logcat -t 80 piped to awk (one-line
# flags only; not full logcat-in-var; no radio files).
ms=`getprop persist.radio.multisim.config`
ss=`getprop gsm.sim.state`
op=`getprop gsm.sim.operator.numeric`
klog "m489 post-itelephony one-shot kmsg scores (no sleep 1; no bind logcat loop; no radio files; no pid-empty wait)"
klog "m494 post-itelephony one-shot greps NAS 0x67 / is_online / FORCE_NW_SEARCH into kmsg (not a loop; do not send 0x67)"
klog "m485 post-itelephony one-shot kmsg scores (no sleep 1; no bind logcat loop; no radio files; no pid-empty wait)"
klog "m484 post-itelephony one-shot kmsg scores (no sleep 1; no bind greps; no radio files; no pid-empty wait)"
klog "m483 post-itelephony one-shot kmsg scores (no sleep 1; no bind greps; no radio files; no pid-empty wait)"
klog "m482 post-itelephony one-shot kmsg scores (no sleep 1; no bind greps; no radio files)"
klog "m474 post-itelephony one-shot kmsg scores (no sleep 1; no bind greps; no radio files)"
klog "m473 post-itelephony one-shot kmsg scores (no sleep 1; no bind greps; no radio files)"
klog "m471 post-itelephony one-shot kmsg scores (no sleep 1; no bind greps; no radio files)"
klog "m469 post-itelephony immediate kmsg scores (no sleep 1; no settings get)"
klog "m468 post-itelephony immediate kmsg scores (no sleep 1; no settings get)"
klog "m457 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op"
klog "m458 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op"
klog "m459 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op air_retry=$AIR_RETRY p1_rp=$P1_RP"
klog "m460 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op air_retry=$AIR_RETRY"
klog "m461 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op air_retry=$AIR_RETRY phone_rebind=$PHONE_REBIND"
klog "m489 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op helper_rp=$HELPER_RP airplane=$AIRPLANE sst=$SST phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN"
klog "m485 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op helper_rp=$HELPER_RP airplane=$AIRPLANE sst=$SST phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN"
klog "m484 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op helper_rp=$HELPER_RP airplane=$AIRPLANE sst=$SST phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN"
klog "m483 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op helper_rp=$HELPER_RP airplane=$AIRPLANE sst=$SST phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN"
klog "m482 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op helper_rp=$HELPER_RP airplane=$AIRPLANE sst=$SST phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN"
klog "m474 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op helper_rp=n airplane=$AIRPLANE sst=$SST phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN"
klog "m473 score persist.radio.multisim.config=$ms gsm.sim.state=$ss gsm.sim.operator.numeric=$op helper_rp=n airplane=$AIRPLANE sst=$SST phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE"
g0=n
ron=n
reg=n
rp=n
rp_on=n
rp_comp=n
su=n
gw=n
# one-shot: pipe logcat to awk; capture ONE flags line only.
# Do not assign full logcat to a variable (m391).
flags=`logcat -b radio -d -t 80 2>/dev/null | awk '
BEGIN { g0="n"; ron="n"; reg="n"; sst="unknown"; rs="none"; rp="n"; rpon="n"; rpc="n"; su="n"; gw="n"; nas67="n"; iso="n"; fnws="n"; bind="n" }
index($0, "known modem operating mode 0") { g0="y" }
index($0, "operating mode 0") { g0="y" }
index($0, "RADIO_ON") { ron="y" }
index($0, "RADIO_STATE_ON") { ron="y" }
index($0, "getRadioState=1") { ron="y" }
index($0, "mVoiceRegState=0(IN_SERVICE)") { reg="y"; sst="IN_SERVICE" }
index($0, "mVoiceRegState=3(POWER_OFF)") { if (sst=="unknown") sst="POWER_OFF" }
index($0, "set service state as POWER_OFF") { if (sst=="unknown") sst="POWER_OFF" }
index($0, "mVoiceRegState=1(OUT_OF_SERVICE)") { if (sst=="unknown") sst="OUT_OF_SERVICE" }
index($0, "set service state as POWER_ON") { if (sst=="unknown") sst="POWER_ON" }
index($0, "RADIO_POWER") { rp="y" }
index($0, "RADIO_POWER on = true") { rpon="y" }
index($0, "RADIO_POWER on=true") { rpon="y" }
index($0, "RIL_REQUEST_RADIO_POWER (23) Complete") { rpc="y" }
index($0, "SET_UICC") { su="y" }
index($0, "setUiccSubscription") { su="y" }
index($0, "subscription 0x0") { if (gw=="n") gw="0" }
index($0, "subscription 0xFFFF") { if (gw=="n") gw="FFFF" }
index($0, "qcril_qmi_nas_force_network_search") { nas67="y" }
index($0, "QMI_NAS_FORCE_NETWORK_SEARCH") { nas67="y" }
index($0, "0x409724") { nas67="y" }
index($0, "is_online") { iso="y" }
index($0, "FORCE_NW_SEARCH") { fnws="y" }
index($0, "FORCE_NETWORK_SEARCH") { fnws="y" }
index($0, "setResponseFunctions non-null") { bind="y" }
index($0, "mRadioResponse non-NULL") { bind="y" }
index($0, "mRadioResponse non-null") { bind="y" }
index($0, "RadioResponse registered") { bind="y" }
index($0, "getRadioState=") {
  p = index($0, "getRadioState=")
  rest = substr($0, p+14, 4)
  n = ""
  for (i=1; i<=length(rest); i++) {
    c = substr(rest, i, 1)
    if (c>="0" && c<="9") n = n c
    else break
  }
  if (n!="") rs=n
}
END { printf "g0=%s ron=%s reg=%s SST=%s RADIO_STATE=%s rp=%s rp_on=%s rp_comp=%s su=%s gw=%s nas67=%s iso=%s fnws=%s bind=%s\n", g0, ron, reg, sst, rs, rp, rpon, rpc, su, gw, nas67, iso, fnws, bind }
'`
case "$flags" in
    *g0=y*) g0=y; POST_GET0=y ;;
esac
case "$flags" in
    *ron=y*) ron=y ;;
esac
case "$flags" in
    *reg=y*) reg=y; SST=IN_SERVICE ;;
esac
case "$flags" in
    *SST=IN_SERVICE*) SST=IN_SERVICE; reg=y ;;
esac
case "$flags" in
    *SST=POWER_OFF*) [ "$reg" = y ] || SST=POWER_OFF ;;
esac
case "$flags" in
    *SST=OUT_OF_SERVICE*) [ "$reg" = y ] || [ "$SST" = POWER_OFF ] || SST=OUT_OF_SERVICE ;;
esac
case "$flags" in
    *SST=POWER_ON*) [ "$reg" = y ] || [ "$SST" = POWER_OFF ] || [ "$SST" = OUT_OF_SERVICE ] || SST=POWER_ON ;;
esac
case "$flags" in
    *rp=y*) rp=y ;;
esac
case "$flags" in
    *rp_on=y*) rp_on=y ;;
esac
case "$flags" in
    *rp_comp=y*) rp_comp=y ;;
esac
case "$flags" in
    *su=y*) su=y ;;
esac
case "$flags" in
    *gw=0*) gw=0 ;;
    *gw=FFFF*) gw=FFFF ;;
esac
case "$flags" in
    *nas67=y*) NAS67=y ;;
esac
case "$flags" in
    *iso=y*) ISO=y ;;
esac
case "$flags" in
    *fnws=y*) FNWS=y ;;
esac
# m489: no post-helper rild restart. get0=y from awk DMS GET /
# operating mode 0 this sit OR helper SET ONLINE completed.
# Not invented QMI.
if [ "$HELPER_RP_COMP" = y ]; then
    klog "m489 helper SET ONLINE + operating mode 0 -- GET0=y"
    klog "m484 helper SET ONLINE + operating mode 0 -- GET0=y"
    klog "m485 helper SET ONLINE before fresh rild — GET 0 may drop; Phone txn 18 must re-ONLINE"
    POST_GET0=y
    POST_OPRT=y
    g0=y
fi
case "$flags" in
    *bind=y*)
        BIND_SEEN=y
        PHONE_BOUND=y
        ;;
esac
RADIO_STATE=`echo "$flags" | tr ' ' '\n' | grep '^RADIO_STATE=' | head -n 1 | sed 's/^RADIO_STATE=//'`
[ -z "$RADIO_STATE" ] && RADIO_STATE=none
klog "m457 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg"
klog "m458 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg"
klog "m459 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg air_retry=$AIR_RETRY p1_rp=$P1_RP p1_comp=$P1_RP_COMP"
klog "m460 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg air_retry=$AIR_RETRY"
klog "m461 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg air_retry=$AIR_RETRY phone_rebind=$PHONE_REBIND"
klog "m489 score GET0=$g0 txn18=y RADIO_ON=$ron sst=$SST gsm.sim=$ss op=$op sst0_in_service=$reg helper_rp=$HELPER_RP bind=$BIND_SEEN nas67=$NAS67"
klog "m489 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp helper_rp=$HELPER_RP SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg sst=$SST airplane=$AIRPLANE phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN nas67=$NAS67"
klog "m494 score NAS 0x67=$NAS67 is_online=$ISO FORCE_NW_SEARCH=$FNWS nas67=$NAS67"
klog "m485 score GET0=$g0 txn18=y RADIO_ON=$ron sst=$SST gsm.sim=$ss op=$op sst0_in_service=$reg helper_rp=$HELPER_RP bind=$BIND_SEEN nas67=$NAS67"
klog "m485 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp helper_rp=$HELPER_RP SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg sst=$SST airplane=$AIRPLANE phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN nas67=$NAS67"
klog "m484 score GET0=$g0 txn18=y RADIO_ON=$ron sst=$SST gsm.sim=$ss op=$op sst0_in_service=$reg helper_rp=$HELPER_RP bind=$BIND_SEEN nas67=$NAS67"
klog "m484 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp helper_rp=$HELPER_RP SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg sst=$SST airplane=$AIRPLANE phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN nas67=$NAS67"
klog "m483 score GET0=$g0 txn18=y RADIO_ON=$ron sst=$SST gsm.sim=$ss op=$op sst0_in_service=$reg helper_rp=$HELPER_RP bind=$BIND_SEEN nas67=$NAS67"
klog "m483 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp helper_rp=$HELPER_RP SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg sst=$SST airplane=$AIRPLANE phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN nas67=$NAS67"
klog "m482 score GET0=$g0 txn18=y RADIO_ON=$ron sst=$SST gsm.sim=$ss op=$op sst0_in_service=$reg helper_rp=$HELPER_RP bind=$BIND_SEEN nas67=$NAS67"
klog "m482 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp helper_rp=$HELPER_RP SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg sst=$SST airplane=$AIRPLANE phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN nas67=$NAS67"
klog "m474 score GET0=$g0 txn18=y RADIO_ON=$ron sst=$SST gsm.sim=$ss op=$op sst0_in_service=$reg helper_rp=n bind=$BIND_SEEN phone_bound=$PHONE_BOUND"
klog "m474 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp helper_rp=n SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg sst=$SST airplane=$AIRPLANE phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN"
klog "m473 score GET0=$g0 txn18=y RADIO_ON=$ron sst=$SST gsm.sim=$ss op=$op sst0_in_service=$reg helper_rp=n"
klog "m473 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp helper_rp=n SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg sst=$SST airplane=$AIRPLANE phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE"
klog "m471 score GET0=$g0 txn18=y RADIO_ON=$ron sst=$SST gsm.sim=$ss op=$op sst0_in_service=$reg helper_rp=$HELPER_RP"
klog "m471 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp helper_rp=$HELPER_RP SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg sst=$SST airplane=$AIRPLANE phone_api=$PHONE_API txn18=y txn=$TXN radio_state=$RADIO_STATE"
klog "m468 score bind_seen=$BIND_SEEN txn18=y getRadioState=$RADIO_STATE RADIO_ON=$ron DMS_GET0=$g0 sst=$SST gsm.sim=$ss op=$op sst0_in_service=$reg"
klog "m467 score RADIO_POWER=$rp on_true=$rp_on Complete=$rp_comp helper_rp=$HELPER_RP SET_UICC=$su GW=$gw DMS_GET0=$g0 sst0_in_service=$reg sst=$SST airplane=$AIRPLANE phone_api=$PHONE_API txn=$TXN radio_state=$RADIO_STATE bind=$BIND_SEEN"
setprop sys.talkman.score_rp $rp
setprop sys.talkman.score_rp_on $rp_on
setprop sys.talkman.score_rp_comp $rp_comp
setprop sys.talkman.score_su $su
setprop sys.talkman.score_gw $gw
setprop sys.talkman.score_g0 $g0
setprop sys.talkman.score_reg $reg
setprop sys.talkman.air_retry $AIR_RETRY
setprop sys.talkman.phone_rebind $PHONE_REBIND
setprop sys.talkman.helper_rp $HELPER_RP
setprop sys.talkman.helper_rp_comp $HELPER_RP_COMP
setprop sys.talkman.sst $SST
setprop sys.talkman.airplane "$AIRPLANE"
setprop sys.talkman.phone_api $PHONE_API
setprop sys.talkman.phone_bound $PHONE_BOUND
setprop sys.talkman.bind $BIND_SEEN
setprop sys.talkman.radio_state "$RADIO_STATE"
setprop sys.talkman.phone_api_txn $TXN
setprop sys.talkman.post_get0 $POST_GET0
setprop sys.talkman.nas67 $NAS67
setprop sys.talkman.is_online $ISO
setprop sys.talkman.force_nw_search $FNWS
# m511: Phone-owned SCREEN_STATE after bind + GET 0 so
# consider can run is_online=1 enable=1. Do not send 0x67.
# Do not helper IRadio. Skip if bind or GET 0 missing.
if [ "$BIND_SEEN" = y ] || [ "$PHONE_BOUND" = y ]; then
    if [ "$g0" = y ] || [ "$POST_GET0" = y ]; then
        input keyevent 224
        klog "m511 input keyevent 224 after Phone bind + GET 0 (SCREEN_STATE re-queue consider; is_online=1 enable=1; do not send 0x67)"
        setprop sys.talkman.nas67_wakeup y
    else
        klog "m511 skip post-GET0 keyevent — GET 0 not scored (bind=$BIND_SEEN g0=$g0)"
        setprop sys.talkman.nas67_wakeup n
    fi
else
    klog "m511 skip post-GET0 keyevent — no Phone bind (SCREEN_STATE would not reach QCRIL)"
    setprop sys.talkman.nas67_wakeup n
fi
# m494: one-shot greps NAS 0x67 / is_online / FORCE_NW_SEARCH
# into kmsg (not a loop; do not send 0x67). Host dmesg dump
# can see them if radio logcat is gone. Not a radio file.
klog "m511 post-GET0 SCREEN_STATE done — one-shot greps NAS 0x67 / is_online / FORCE_NW_SEARCH into kmsg (not a loop; do not send 0x67)"
klog "m494 one-shot greps NAS 0x67 / is_online / FORCE_NW_SEARCH into kmsg (not a loop; do not send 0x67)"
logcat -b radio -d -t 80 2>/dev/null | grep -E '0x67|is_online|FORCE_NW_SEARCH' | tail -n 8 > /dev/kmsg
# Quiet: getprop gsm.* only. No dumpsys. No extra radio files.
exit 0
