// m349: minimal HIDL client for android.hardware.radio@1.0::IRadio/slot1
// setResponseFunctions stub + setRadioPower(true). Not a QMI client.
// m381: argv "setuicc" = setUiccSubscription slot=0 appIndex=0 USIM
// activate=true. First-stage MS_BIND onto /vendor/bin/qmakernote-xtract.
// Never leftover /data/local/tmp/talkman-iradio-on.
// m383: argv "card"/"peek" = getIccCardStatus only. argv "setuicc"
// refuses card=0 (do not SET_UICC on ABSENT). Same HIDL as Phone.
// m389: setuicc after Phone bound does NOT call setResponseFunctions
// (keeps Phone mRadioIndication).
// m396: Phone not bound (phase1 fast) uses own HIDL callbacks then
// do_set_uicc after peek PRESENT — same path as m387. Do not fake
// phone_bound. Do not invent QMI. Default (no args) stays
// setRadioPower(true) only.
// m462: argv "power"/"radiopower" = setRadioPower(true) with own
// callbacks ONLY while Phone is down (wait.sh force-stop first).
// Same HIDL pattern as SET_UICC — not a steal, not a QMI client.
// Refuse if sys.talkman.phone_bound is y. Do not hold IRadio after
// Phone comes back (process exits).
// m467: after Complete, release IRadio — setResponseFunctions(null)
// destroys rild callbacks, drop the service, then process exit.
// SET_UICC already returned then exited (earlier sits: Phone SST
// OUT_OF_SERVICE + LOADED). Explicit null-callbacks so death
// cannot leave mRadioResponse==NULL for Phone. Not a QMI client.
// Author archienz.
// m400: argv "bandpref" = IOemHook sendRequestRaw
// QCRIL_EVT_HOOK_SET_PREFERRED_NETWORK_BAND_PREF (qcrilhook.jar 524325)
// band_pref_map=1 → blob qmi_ril_nas_cache_deferred_band_pref copies
// persist.radio.lte_full_band. QcRilHook header is QOEMHOOK + id +
// len + payload. persist.radio.oem_socket=0 so rild (not oem socket)
// dispatches the hook. Not a QMI client. Do not steal IRadio.
// Author archienz.
#define LOG_TAG "talkman-iradio-on"
#include <android/hardware/radio/1.0/IRadio.h>
#include <android/hardware/radio/1.0/IRadioIndication.h>
#include <android/hardware/radio/1.0/IRadioResponse.h>
#include <android/hardware/radio/1.0/types.h>
#include <android/hardware/radio/deprecated/1.0/IOemHook.h>
#include <android/hardware/radio/deprecated/1.0/IOemHookIndication.h>
#include <android/hardware/radio/deprecated/1.0/IOemHookResponse.h>
#include <cutils/properties.h>
#include <hwbinder/ProcessState.h>
#include <log/log.h>
#include <utils/StrongPointer.h>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <mutex>

using ::android::sp;
using ::android::hardware::hidl_string;
using ::android::hardware::hidl_vec;
using ::android::hardware::Return;
using ::android::hardware::Void;
using ::android::hardware::radio::V1_0::IRadio;
using ::android::hardware::radio::V1_0::IRadioIndication;
using ::android::hardware::radio::V1_0::IRadioResponse;
using ::android::hardware::radio::V1_0::AppType;
using ::android::hardware::radio::V1_0::CardState;
using ::android::hardware::radio::V1_0::CardStatus;
using ::android::hardware::radio::V1_0::RadioIndicationType;
using ::android::hardware::radio::V1_0::RadioResponseInfo;
using ::android::hardware::radio::V1_0::RadioState;
using ::android::hardware::radio::V1_0::SelectUiccSub;
using ::android::hardware::radio::V1_0::SubscriptionType;
using ::android::hardware::radio::V1_0::UiccSubActStatus;
using ::android::hardware::radio::deprecated::V1_0::IOemHook;
using ::android::hardware::radio::deprecated::V1_0::IOemHookIndication;
using ::android::hardware::radio::deprecated::V1_0::IOemHookResponse;

// vendor/msft/talkman/.../qcrilhook.jar IQcRilHook (not invented):
// QCRIL_EVT_HOOK_SET_PREFERRED_NETWORK_BAND_PREF = 524325 (0x80025)
// blob qcril_qmi_nas_request_set_preferred_network_band_pref @ 0x41ba88
// accepts band_pref_map 1/2/3; 1 = full persist.radio.lte_full_band.
static const uint32_t QCRIL_EVT_HOOK_SET_PREFERRED_NETWORK_BAND_PREF = 524325;

static void klog(const char* s) {
    FILE* f = fopen("/dev/kmsg", "w");
    if (f) {
        fprintf(f, "%s\n", s);
        fclose(f);
    }
    ALOGI("%s", s);
}

static void write_card_file(int err, int card, int gsm_id, int napp,
                            int at0, int as0, bool present, bool usim) {
    FILE* f = fopen("/data/local/tmp/m383-card.st", "w");
    if (f) {
        fprintf(f,
                "card=%d\nerr=%d\ngsm_id=%d\npresent=%s\nusim=%s\napps=%d\n"
                "app0_type=%d\napp0_state=%d\n",
                card, err, gsm_id, present ? "y" : "n", usim ? "y" : "n",
                napp, at0, as0);
        fclose(f);
    }
    char b[16];
    snprintf(b, sizeof(b), "%d", card);
    property_set("sys.talkman.card", b);
    property_set("sys.talkman.uim_present", present ? "y" : "n");
    property_set("sys.talkman.usim", usim ? "y" : "n");
    snprintf(b, sizeof(b), "%d", gsm_id);
    property_set("sys.talkman.gsm_id", b);
}

struct RadioRsp : public IRadioResponse {
    std::mutex mu;
    std::condition_variable cv;
    bool got = false;
    bool got_uicc = false;
    bool got_card = false;
    RadioResponseInfo last{};
    CardStatus last_card{};

    Return<void> getIccCardStatusResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::CardStatus& cardStatus) override {
        int napp = (int)cardStatus.applications.size();
        int at0 = napp > 0 ? (int)cardStatus.applications[0].appType : -1;
        int as0 = napp > 0 ? (int)cardStatus.applications[0].appState : -1;
        char buf[288];
        snprintf(buf, sizeof(buf),
                 "m383 IRadio getIccCardStatus serial=%d err=%d card=%d gsm_id=%d apps=%d app0_type=%d app0_state=%d",
                 info.serial, (int)info.error, (int)cardStatus.cardState,
                 cardStatus.gsmUmtsSubscriptionAppIndex, napp, at0, as0);
        klog(buf);
        {
            std::lock_guard<std::mutex> lk(mu);
            last = info;
            last_card = cardStatus;
            got_card = true;
        }
        cv.notify_all();
        return Void();
    }
    Return<void> supplyIccPinForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t remainingRetries) override { return Void(); }
    Return<void> supplyIccPukForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t remainingRetries) override { return Void(); }
    Return<void> supplyIccPin2ForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t remainingRetries) override { return Void(); }
    Return<void> supplyIccPuk2ForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t remainingRetries) override { return Void(); }
    Return<void> changeIccPinForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t remainingRetries) override { return Void(); }
    Return<void> changeIccPin2ForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t remainingRetries) override { return Void(); }
    Return<void> supplyNetworkDepersonalizationResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t remainingRetries) override { return Void(); }
    Return<void> getCurrentCallsResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::Call>& calls) override { return Void(); }
    Return<void> dialResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getIMSIForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_string& imsi) override { return Void(); }
    Return<void> hangupConnectionResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> hangupWaitingOrBackgroundResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> hangupForegroundResumeBackgroundResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> switchWaitingOrHoldingAndActiveResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> conferenceResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> rejectCallResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getLastCallFailCauseResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::LastCallFailCauseInfo& failCauseinfo) override { return Void(); }
    Return<void> getSignalStrengthResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::SignalStrength& sigStrength) override { return Void(); }
    Return<void> getVoiceRegistrationStateResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::VoiceRegStateResult& voiceRegResponse) override { return Void(); }
    Return<void> getDataRegistrationStateResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::DataRegStateResult& dataRegResponse) override { return Void(); }
    Return<void> getOperatorResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_string& longName, const ::android::hardware::hidl_string& shortName, const ::android::hardware::hidl_string& numeric) override { return Void(); }
    Return<void> setRadioPowerResponse(const RadioResponseInfo& info) override {
        char buf[256];
        snprintf(buf, sizeof(buf),
                 "m349 IRadio setRadioPowerResponse serial=%d type=%d error=%d",
                 info.serial, (int)info.type, (int)info.error);
        klog(buf);
        snprintf(buf, sizeof(buf),
                 "m462 IRadio setRadioPowerResponse serial=%d type=%d error=%d",
                 info.serial, (int)info.type, (int)info.error);
        klog(buf);
        {
            std::lock_guard<std::mutex> lk(mu);
            last = info;
            got = true;
        }
        cv.notify_all();
        char eb[16];
        snprintf(eb, sizeof(eb), "%d", (int)info.error);
        property_set("sys.talkman.helper_rp_err", eb);
        property_set("sys.talkman.helper_rp_comp",
                     (int)info.error == 0 ? "y" : "n");
        FILE* d = fopen("/data/local/tmp/m349-iradio-on.done", "w");
        if (d) {
            fprintf(d, "%s\n", buf);
            fclose(d);
        }
        return Void();
    }
    Return<void> sendDtmfResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> sendSmsResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::SendSmsResult& sms) override { return Void(); }
    Return<void> sendSMSExpectMoreResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::SendSmsResult& sms) override { return Void(); }
    Return<void> setupDataCallResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::SetupDataCallResult& dcResponse) override { return Void(); }
    Return<void> iccIOForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::IccIoResult& iccIo) override { return Void(); }
    Return<void> sendUssdResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> cancelPendingUssdResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getClirResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t n, int32_t m) override { return Void(); }
    Return<void> setClirResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getCallForwardStatusResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::CallForwardInfo>& callForwardInfos) override { return Void(); }
    Return<void> setCallForwardResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getCallWaitingResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, bool enable, int32_t serviceClass) override { return Void(); }
    Return<void> setCallWaitingResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> acknowledgeLastIncomingGsmSmsResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> acceptCallResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> deactivateDataCallResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getFacilityLockForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t response) override { return Void(); }
    Return<void> setFacilityLockForAppResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t retry) override { return Void(); }
    Return<void> setBarringPasswordResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getNetworkSelectionModeResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, bool manual) override { return Void(); }
    Return<void> setNetworkSelectionModeAutomaticResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setNetworkSelectionModeManualResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getAvailableNetworksResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::OperatorInfo>& networkInfos) override { return Void(); }
    Return<void> startDtmfResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> stopDtmfResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getBasebandVersionResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_string& version) override { return Void(); }
    Return<void> separateConnectionResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setMuteResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getMuteResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, bool enable) override { return Void(); }
    Return<void> getClipResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, ::android::hardware::radio::V1_0::ClipStatus status) override { return Void(); }
    Return<void> getDataCallListResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::SetupDataCallResult>& dcResponse) override { return Void(); }
    Return<void> setSuppServiceNotificationsResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> writeSmsToSimResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t index) override { return Void(); }
    Return<void> deleteSmsOnSimResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setBandModeResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getAvailableBandModesResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::RadioBandMode>& bandModes) override { return Void(); }
    Return<void> sendEnvelopeResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_string& commandResponse) override { return Void(); }
    Return<void> sendTerminalResponseToSimResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> handleStkCallSetupRequestFromSimResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> explicitCallTransferResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setPreferredNetworkTypeResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getPreferredNetworkTypeResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, ::android::hardware::radio::V1_0::PreferredNetworkType nwType) override { return Void(); }
    Return<void> getNeighboringCidsResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::NeighboringCell>& cells) override { return Void(); }
    Return<void> setLocationUpdatesResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setCdmaSubscriptionSourceResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setCdmaRoamingPreferenceResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getCdmaRoamingPreferenceResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, ::android::hardware::radio::V1_0::CdmaRoamingType type) override { return Void(); }
    Return<void> setTTYModeResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getTTYModeResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, ::android::hardware::radio::V1_0::TtyMode mode) override { return Void(); }
    Return<void> setPreferredVoicePrivacyResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getPreferredVoicePrivacyResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, bool enable) override { return Void(); }
    Return<void> sendCDMAFeatureCodeResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> sendBurstDtmfResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> sendCdmaSmsResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::SendSmsResult& sms) override { return Void(); }
    Return<void> acknowledgeLastIncomingCdmaSmsResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getGsmBroadcastConfigResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::GsmBroadcastSmsConfigInfo>& configs) override { return Void(); }
    Return<void> setGsmBroadcastConfigResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setGsmBroadcastActivationResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getCdmaBroadcastConfigResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::CdmaBroadcastSmsConfigInfo>& configs) override { return Void(); }
    Return<void> setCdmaBroadcastConfigResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setCdmaBroadcastActivationResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getCDMASubscriptionResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_string& mdn, const ::android::hardware::hidl_string& hSid, const ::android::hardware::hidl_string& hNid, const ::android::hardware::hidl_string& min, const ::android::hardware::hidl_string& prl) override { return Void(); }
    Return<void> writeSmsToRuimResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, uint32_t index) override { return Void(); }
    Return<void> deleteSmsOnRuimResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getDeviceIdentityResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_string& imei, const ::android::hardware::hidl_string& imeisv, const ::android::hardware::hidl_string& esn, const ::android::hardware::hidl_string& meid) override { return Void(); }
    Return<void> exitEmergencyCallbackModeResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getSmscAddressResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_string& smsc) override { return Void(); }
    Return<void> setSmscAddressResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> reportSmsMemoryStatusResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> reportStkServiceIsRunningResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getCdmaSubscriptionSourceResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, ::android::hardware::radio::V1_0::CdmaSubscriptionSource source) override { return Void(); }
    Return<void> requestIsimAuthenticationResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_string& response) override { return Void(); }
    Return<void> acknowledgeIncomingGsmSmsWithPduResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> sendEnvelopeWithStatusResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::IccIoResult& iccIo) override { return Void(); }
    Return<void> getVoiceRadioTechnologyResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, ::android::hardware::radio::V1_0::RadioTechnology rat) override { return Void(); }
    Return<void> getCellInfoListResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::CellInfo>& cellInfo) override { return Void(); }
    Return<void> setCellInfoListRateResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setInitialAttachApnResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getImsRegistrationStateResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, bool isRegistered, ::android::hardware::radio::V1_0::RadioTechnologyFamily ratFamily) override { return Void(); }
    Return<void> sendImsSmsResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::SendSmsResult& sms) override { return Void(); }
    Return<void> iccTransmitApduBasicChannelResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::IccIoResult& result) override { return Void(); }
    Return<void> iccOpenLogicalChannelResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t channelId, const ::android::hardware::hidl_vec<int8_t>& selectResponse) override { return Void(); }
    Return<void> iccCloseLogicalChannelResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> iccTransmitApduLogicalChannelResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::IccIoResult& result) override { return Void(); }
    Return<void> nvReadItemResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_string& result) override { return Void(); }
    Return<void> nvWriteItemResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> nvWriteCdmaPrlResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> nvResetConfigResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setUiccSubscriptionResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override {
        char buf[256];
        snprintf(buf, sizeof(buf),
                 "m383 IRadio setUiccSubscriptionResponse serial=%d type=%d error=%d",
                 info.serial, (int)info.type, (int)info.error);
        klog(buf);
        {
            std::lock_guard<std::mutex> lk(mu);
            last = info;
            got_uicc = true;
        }
        cv.notify_all();
        FILE* d = fopen("/data/local/tmp/m383-set-uicc.done", "w");
        if (d) {
            fprintf(d, "%s\n", buf);
            fclose(d);
        }
        char eb[16];
        snprintf(eb, sizeof(eb), "%d", (int)info.error);
        property_set("sys.talkman.set_uicc_err", eb);
        return Void();
    }
    Return<void> setDataAllowedResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getHardwareConfigResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::HardwareConfig>& config) override { return Void(); }
    Return<void> requestIccSimAuthenticationResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::IccIoResult& result) override { return Void(); }
    Return<void> setDataProfileResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> requestShutdownResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> getRadioCapabilityResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::RadioCapability& rc) override { return Void(); }
    Return<void> setRadioCapabilityResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::RadioCapability& rc) override { return Void(); }
    Return<void> startLceServiceResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::LceStatusInfo& statusInfo) override { return Void(); }
    Return<void> stopLceServiceResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::LceStatusInfo& statusInfo) override { return Void(); }
    Return<void> pullLceDataResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::LceDataInfo& lceInfo) override { return Void(); }
    Return<void> getModemActivityInfoResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, const ::android::hardware::radio::V1_0::ActivityStatsInfo& activityInfo) override { return Void(); }
    Return<void> setAllowedCarriersResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, int32_t numAllowed) override { return Void(); }
    Return<void> getAllowedCarriersResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info, bool allAllowed, const ::android::hardware::radio::V1_0::CarrierRestrictions& carriers) override { return Void(); }
    Return<void> sendDeviceStateResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setIndicationFilterResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> setSimCardPowerResponse(const ::android::hardware::radio::V1_0::RadioResponseInfo& info) override { return Void(); }
    Return<void> acknowledgeRequest(int32_t serial) override { return Void(); }
};

struct RadioInd : public IRadioIndication {
    Return<void> radioStateChanged(RadioIndicationType /*type*/, RadioState radioState) override {
        char buf[192];
        snprintf(buf, sizeof(buf), "m349 IRadio radioStateChanged state=%d", (int)radioState);
        klog(buf);
        return Void();
    }
    Return<void> callStateChanged(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> networkStateChanged(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> newSms(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_vec<uint8_t>& pdu) override { return Void(); }
    Return<void> newSmsStatusReport(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_vec<uint8_t>& pdu) override { return Void(); }
    Return<void> newSmsOnSim(::android::hardware::radio::V1_0::RadioIndicationType type, int32_t recordNumber) override { return Void(); }
    Return<void> onUssd(::android::hardware::radio::V1_0::RadioIndicationType type, ::android::hardware::radio::V1_0::UssdModeType modeType, const ::android::hardware::hidl_string& msg) override { return Void(); }
    Return<void> nitzTimeReceived(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_string& nitzTime, uint64_t receivedTime) override { return Void(); }
    Return<void> currentSignalStrength(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::SignalStrength& signalStrength) override { return Void(); }
    Return<void> dataCallListChanged(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::SetupDataCallResult>& dcList) override { return Void(); }
    Return<void> suppSvcNotify(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::SuppSvcNotification& suppSvc) override { return Void(); }
    Return<void> stkSessionEnd(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> stkProactiveCommand(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_string& cmd) override { return Void(); }
    Return<void> stkEventNotify(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_string& cmd) override { return Void(); }
    Return<void> stkCallSetup(::android::hardware::radio::V1_0::RadioIndicationType type, int64_t timeout) override { return Void(); }
    Return<void> simSmsStorageFull(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> simRefresh(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::SimRefreshResult& refreshResult) override { return Void(); }
    Return<void> callRing(::android::hardware::radio::V1_0::RadioIndicationType type, bool isGsm, const ::android::hardware::radio::V1_0::CdmaSignalInfoRecord& record) override { return Void(); }
    Return<void> simStatusChanged(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> cdmaNewSms(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::CdmaSmsMessage& msg) override { return Void(); }
    Return<void> newBroadcastSms(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_vec<uint8_t>& data) override { return Void(); }
    Return<void> cdmaRuimSmsStorageFull(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> restrictedStateChanged(::android::hardware::radio::V1_0::RadioIndicationType type, ::android::hardware::radio::V1_0::PhoneRestrictedState state) override { return Void(); }
    Return<void> enterEmergencyCallbackMode(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> cdmaCallWaiting(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::CdmaCallWaiting& callWaitingRecord) override { return Void(); }
    Return<void> cdmaOtaProvisionStatus(::android::hardware::radio::V1_0::RadioIndicationType type, ::android::hardware::radio::V1_0::CdmaOtaProvisionStatus status) override { return Void(); }
    Return<void> cdmaInfoRec(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::CdmaInformationRecords& records) override { return Void(); }
    Return<void> indicateRingbackTone(::android::hardware::radio::V1_0::RadioIndicationType type, bool start) override { return Void(); }
    Return<void> resendIncallMute(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> cdmaSubscriptionSourceChanged(::android::hardware::radio::V1_0::RadioIndicationType type, ::android::hardware::radio::V1_0::CdmaSubscriptionSource cdmaSource) override { return Void(); }
    Return<void> cdmaPrlChanged(::android::hardware::radio::V1_0::RadioIndicationType type, int32_t version) override { return Void(); }
    Return<void> exitEmergencyCallbackMode(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> rilConnected(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> voiceRadioTechChanged(::android::hardware::radio::V1_0::RadioIndicationType type, ::android::hardware::radio::V1_0::RadioTechnology rat) override { return Void(); }
    Return<void> cellInfoList(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::CellInfo>& records) override { return Void(); }
    Return<void> imsNetworkStateChanged(::android::hardware::radio::V1_0::RadioIndicationType type) override { return Void(); }
    Return<void> subscriptionStatusChanged(::android::hardware::radio::V1_0::RadioIndicationType type, bool activate) override { return Void(); }
    Return<void> srvccStateNotify(::android::hardware::radio::V1_0::RadioIndicationType type, ::android::hardware::radio::V1_0::SrvccState state) override { return Void(); }
    Return<void> hardwareConfigChanged(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_vec<::android::hardware::radio::V1_0::HardwareConfig>& configs) override { return Void(); }
    Return<void> radioCapabilityIndication(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::RadioCapability& rc) override { return Void(); }
    Return<void> onSupplementaryServiceIndication(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::StkCcUnsolSsResult& ss) override { return Void(); }
    Return<void> stkCallControlAlphaNotify(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_string& alpha) override { return Void(); }
    Return<void> lceData(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::LceDataInfo& lce) override { return Void(); }
    Return<void> pcoData(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::radio::V1_0::PcoDataInfo& pco) override { return Void(); }
    Return<void> modemReset(::android::hardware::radio::V1_0::RadioIndicationType type, const ::android::hardware::hidl_string& reason) override { return Void(); }
};

struct OemHookRsp : public IOemHookResponse {
    std::mutex mu;
    std::condition_variable cv;
    bool got = false;
    RadioResponseInfo last{};

    Return<void> sendRequestRawResponse(const RadioResponseInfo& info,
                                        const hidl_vec<uint8_t>& /*data*/) override {
        char buf[192];
        snprintf(buf, sizeof(buf),
                 "m400 IOemHook sendRequestRawResponse serial=%d type=%d error=%d",
                 info.serial, (int)info.type, (int)info.error);
        klog(buf);
        {
            std::lock_guard<std::mutex> lk(mu);
            last = info;
            got = true;
        }
        cv.notify_all();
        property_set("sys.talkman.bandpref_err", (int)info.error == 0 ? "0" : "e");
        return Void();
    }
    Return<void> sendRequestStringsResponse(
            const RadioResponseInfo& info,
            const hidl_vec<hidl_string>& /*data*/) override {
        (void)info;
        return Void();
    }
};

struct OemHookInd : public IOemHookIndication {
    Return<void> oemHookRaw(RadioIndicationType /*type*/,
                            const hidl_vec<uint8_t>& /*data*/) override {
        return Void();
    }
};

static bool card_has_usim(const CardStatus& card) {
    for (size_t i = 0; i < card.applications.size(); i++) {
        if (card.applications[i].appType == AppType::USIM) {
            return true;
        }
    }
    return false;
}

static int do_card_peek(const sp<IRadio>& radio, const sp<RadioRsp>& rsp, int32_t serial) {
    klog("m383 IRadio getIccCardStatus peek");
    {
        std::lock_guard<std::mutex> lk(rsp->mu);
        rsp->got_card = false;
    }
    Return<void> g = radio->getIccCardStatus(serial);
    if (!g.isOk()) {
        klog("m383 IRadio getIccCardStatus transport failed");
        write_card_file(-1, 0, -1, 0, -1, -1, false, false);
        return 4;
    }
    std::unique_lock<std::mutex> lk(rsp->mu);
    bool ok = rsp->cv.wait_for(lk, std::chrono::seconds(2), [&] { return rsp->got_card; });
    if (!ok) {
        klog("m383 IRadio getIccCardStatus peek timeout");
        write_card_file(-2, 0, -1, 0, -1, -1, false, false);
        return 5;
    }
    int card = (int)rsp->last_card.cardState;
    int err = (int)rsp->last.error;
    int gsm_id = rsp->last_card.gsmUmtsSubscriptionAppIndex;
    int napp = (int)rsp->last_card.applications.size();
    int at0 = napp > 0 ? (int)rsp->last_card.applications[0].appType : -1;
    int as0 = napp > 0 ? (int)rsp->last_card.applications[0].appState : -1;
    bool present = (rsp->last_card.cardState == CardState::PRESENT);
    bool usim = card_has_usim(rsp->last_card);
    write_card_file(err, card, gsm_id, napp, at0, as0, present, usim);
    char b[192];
    snprintf(b, sizeof(b), "m383 IRadio peek card=%d present=%d usim=%d gsm_id=%d err=%d",
             card, present ? 1 : 0, usim ? 1 : 0, gsm_id, err);
    klog(b);
    if (present) {
        return 0;
    }
    klog("m383 IRadio peek card=0 — not PRESENT");
    return 1;
}

static int do_bandpref() {
    klog("m400 IOemHook SET_PREFERRED_NETWORK_BAND_PREF map=1");
    android::hardware::ProcessState::self()->startThreadPool();
    sp<IOemHook> hook = IOemHook::getService("slot1");
    if (hook == nullptr) {
        klog("m400 IOemHook getService slot1 failed");
        property_set("sys.talkman.bandpref", "n");
        return 2;
    }
    klog("m400 IOemHook getService slot1 ok");
    sp<OemHookRsp> rsp = new OemHookRsp();
    sp<OemHookInd> ind = new OemHookInd();
    Return<void> sr = hook->setResponseFunctions(rsp, ind);
    if (!sr.isOk()) {
        klog("m400 IOemHook setResponseFunctions failed");
        property_set("sys.talkman.bandpref", "n");
        return 3;
    }
    // QcRilHook: "QOEMHOOK" + LE request_id + LE payload_len + payload.
    // Handler @ 0x41ba88 reads *(uint32_t*)params->data as band_pref_map.
    hidl_vec<uint8_t> data;
    data.resize(20);
    memcpy(&data[0], "QOEMHOOK", 8);
    uint32_t req = QCRIL_EVT_HOOK_SET_PREFERRED_NETWORK_BAND_PREF;
    uint32_t plen = 4;
    uint32_t map = 1;
    memcpy(&data[8], &req, 4);
    memcpy(&data[12], &plen, 4);
    memcpy(&data[16], &map, 4);
    Return<void> sent = hook->sendRequestRaw(400, data);
    if (!sent.isOk()) {
        klog("m400 IOemHook sendRequestRaw transport failed");
        property_set("sys.talkman.bandpref", "n");
        return 4;
    }
    klog("m400 IOemHook sendRequestRaw issued QcRilHook 20B map=1");
    std::unique_lock<std::mutex> lk(rsp->mu);
    bool ok = rsp->cv.wait_for(lk, std::chrono::seconds(8), [&] { return rsp->got; });
    if (!ok) {
        klog("m400 IOemHook SET_PREFERRED_NETWORK_BAND_PREF timeout");
        property_set("sys.talkman.bandpref", "timeout");
        return 5;
    }
    int err = (int)rsp->last.error;
    if (err == 0) {
        klog("m400 IOemHook SET_PREFERRED_NETWORK_BAND_PREF Success");
        property_set("sys.talkman.bandpref", "y");
        return 0;
    }
    char b[96];
    snprintf(b, sizeof(b), "m400 IOemHook SET_PREFERRED_NETWORK_BAND_PREF error=%d", err);
    klog(b);
    property_set("sys.talkman.bandpref", "n");
    return 6;
}

static void release_iradio(sp<IRadio>& radio, const char* why) {
    char b[224];
    snprintf(b, sizeof(b),
             "m467 IRadio release %s — destroy callbacks then drop service then exit",
             why ? why : "?");
    klog(b);
    if (radio != nullptr) {
        Return<void> clr = radio->setResponseFunctions(nullptr, nullptr);
        if (!clr.isOk()) {
            klog("m467 IRadio release setResponseFunctions(null) transport failed — still drop");
        } else {
            klog("m467 IRadio release setResponseFunctions(null) ok");
        }
        radio.clear();
    } else {
        klog("m467 IRadio release radio already null");
    }
}

static int do_set_radio_power(const sp<IRadio>& radio, const sp<RadioRsp>& rsp,
                             bool phone_down) {
    int32_t serial = phone_down ? 462 : 349;
    int wait_s = phone_down ? 3 : 8;
    char b[192];
    snprintf(b, sizeof(b),
             "m349 IRadio setRadioPower(true) serial=%d", serial);
    klog(b);
    if (phone_down) {
        klog("m462 IRadio setRadioPower(true) serial=462 Phone down");
        property_set("sys.talkman.helper_rp", "n");
        property_set("sys.talkman.helper_rp_comp", "n");
        property_set("sys.talkman.helper_rp_err", "none");
    }
    Return<void> rp = radio->setRadioPower(serial, true);
    if (!rp.isOk()) {
        klog("m349 IRadio setRadioPower transport failed");
        if (phone_down) {
            klog("m462 IRadio setRadioPower transport failed");
            property_set("sys.talkman.helper_rp", "n");
        }
        return 4;
    }
    klog("m349 IRadio setRadioPower(true) issued");
    if (phone_down) {
        klog("m462 IRadio setRadioPower(true) issued");
        property_set("sys.talkman.helper_rp", "y");
    }
    std::unique_lock<std::mutex> lk(rsp->mu);
    bool ok = rsp->cv.wait_for(lk, std::chrono::seconds(wait_s),
                               [&] { return rsp->got; });
    if (ok) {
        klog("m349 IRadio SET ONLINE completed");
        if (phone_down) {
            int err = (int)rsp->last.error;
            snprintf(b, sizeof(b),
                     "m462 IRadio SET ONLINE completed err=%d", err);
            klog(b);
            if (err == 0) {
                property_set("sys.talkman.helper_rp_comp", "y");
            }
        }
        return 0;
    }
    klog("m349 IRadio SET ONLINE timeout");
    if (phone_down) {
        klog("m462 IRadio SET ONLINE timeout");
        property_set("sys.talkman.helper_rp_comp", "n");
    }
    return 5;
}

static int do_set_uicc(const sp<IRadio>& radio, const sp<RadioRsp>& rsp) {
    klog("m383 IRadio setUicc SET_UICC after PRESENT only");
    int peek_rc = do_card_peek(radio, rsp, 1383);
    bool present = false;
    int card = 0;
    {
        std::lock_guard<std::mutex> lk(rsp->mu);
        present = (rsp->got_card && rsp->last_card.cardState == CardState::PRESENT);
        card = rsp->got_card ? (int)rsp->last_card.cardState : 0;
    }
    if (peek_rc != 0 || !present || card == 0) {
        klog("m383 IRadio do not setuicc on card=0");
        property_set("sys.talkman.set_uicc", "n");
        property_set("sys.talkman.set_uicc_after_present", "n");
        property_set("sys.talkman.set_uicc_err", "card0");
        return 8;
    }
    SelectUiccSub sub{};
    sub.slot = 0;
    sub.appIndex = 0;
    sub.subType = SubscriptionType::SUBSCRIPTION_1;
    sub.actStatus = UiccSubActStatus::ACTIVATE;
    klog("m383 IRadio setUiccSubscription serial=383 slot=0 appIndex=0 USIM activate=true");
    Return<void> su = radio->setUiccSubscription(383, sub);
    if (!su.isOk()) {
        klog("m383 IRadio setUiccSubscription transport failed");
        return 6;
    }
    klog("m383 IRadio setUiccSubscription issued");
    property_set("sys.talkman.set_uicc_after_present", "y");
    std::unique_lock<std::mutex> lk(rsp->mu);
    bool ok = rsp->cv.wait_for(lk, std::chrono::seconds(8), [&] { return rsp->got_uicc; });
    if (ok) {
        klog("m383 IRadio SET_UICC completed");
        return 0;
    }
    klog("m383 IRadio SET_UICC timeout");
    return 7;
}

static int do_set_uicc_keep(const sp<IRadio>& radio) {
    klog("m383 IRadio setUicc SET_UICC after PRESENT only");
    char cardp[92];
    property_get("sys.talkman.card", cardp, "0");
    if (strcmp(cardp, "0") == 0) {
        klog("m383 IRadio do not setuicc on card=0");
        property_set("sys.talkman.set_uicc", "n");
        property_set("sys.talkman.set_uicc_after_present", "n");
        property_set("sys.talkman.set_uicc_err", "card0");
        return 8;
    }
    klog("m389 IRadio keep Phone setResponseFunctions — issue SET_UICC only");
    SelectUiccSub sub{};
    sub.slot = 0;
    sub.appIndex = 0;
    sub.subType = SubscriptionType::SUBSCRIPTION_1;
    sub.actStatus = UiccSubActStatus::ACTIVATE;
    klog("m383 IRadio setUiccSubscription serial=383 slot=0 appIndex=0 USIM activate=true");
    Return<void> su = radio->setUiccSubscription(383, sub);
    if (!su.isOk()) {
        klog("m383 IRadio setUiccSubscription transport failed");
        return 6;
    }
    klog("m383 IRadio setUiccSubscription issued");
    klog("m389 IRadio SET_UICC issued keep-indication");
    property_set("sys.talkman.set_uicc_after_present", "y");
    FILE* d = fopen("/data/local/tmp/m383-set-uicc.done", "w");
    if (d) {
        fprintf(d, "m389 IRadio SET_UICC issued keep-indication\n");
        fclose(d);
    }
    FILE* d2 = fopen("/data/local/tmp/m381-set-uicc.done", "w");
    if (d2) {
        fprintf(d2, "issued\n");
        fclose(d2);
    }
    return 0;
}

int main(int argc, char** argv) {
    bool want_uicc = false;
    bool want_card = false;
    bool want_power = false;
    char startbuf[256];
    snprintf(startbuf, sizeof(startbuf), "m383 IRadio argv0=%s argc=%d",
             (argc > 0 && argv[0]) ? argv[0] : "?", argc);
    klog(startbuf);
    if (argc > 1 && strcmp(argv[1], "bandpref") == 0) {
        klog("m400 IOemHook client start bandpref");
        return do_bandpref();
    }
    if (argc > 1 && strcmp(argv[1], "setuicc") == 0) {
        want_uicc = true;
        klog("m383 IRadio client start setuicc");
    } else if (argc > 1 && (strcmp(argv[1], "card") == 0 || strcmp(argv[1], "peek") == 0)) {
        want_card = true;
        klog("m383 IRadio client start card peek");
    } else if (argc > 1 && (strcmp(argv[1], "power") == 0 ||
                            strcmp(argv[1], "radiopower") == 0 ||
                            strcmp(argv[1], "setradiopower") == 0)) {
        want_power = true;
        klog("m462 IRadio client start power (Phone down)");
    } else {
        klog("m349 IRadio client start");
    }
    android::hardware::ProcessState::self()->startThreadPool();
    sp<IRadio> radio = IRadio::getService("slot1");
    if (radio == nullptr) {
        klog("m349 IRadio getService slot1 failed");
        if (want_power) {
            klog("m462 IRadio getService slot1 failed");
            property_set("sys.talkman.helper_rp", "n");
        }
        return 2;
    }
    klog("m349 IRadio getService slot1 ok");
    if (want_uicc) {
        char bound[92];
        property_get("sys.talkman.phone_bound", bound, "");
        if (strcmp(bound, "y") == 0 || strcmp(bound, "1") == 0) {
            int krc = do_set_uicc_keep(radio);
            radio.clear();
            klog("m467 IRadio drop service after keep-SET_UICC — did not destroy Phone callbacks");
            return krc;
        }
        // m396 / m387: Phone not started. Own callbacks, then SET_UICC
        // after peek PRESENT. Do not fake phone_bound. Not a QMI client.
        klog("m396 IRadio SET_UICC own callbacks — Phone not bound (m387 path)");
        klog("m396 do not wait Phone bind for SET_UICC");
        sp<RadioRsp> ursp = new RadioRsp();
        sp<RadioInd> uind = new RadioInd();
        Return<void> usr = radio->setResponseFunctions(ursp, uind);
        if (!usr.isOk()) {
            klog("m349 IRadio setResponseFunctions failed");
            release_iradio(radio, "setuicc-srf-fail");
            return 3;
        }
        klog("m349 IRadio setResponseFunctions ok");
        int urc = do_set_uicc(radio, ursp);
        release_iradio(radio, "setuicc");
        return urc;
    }
    if (want_power) {
        char bound[92];
        property_get("sys.talkman.phone_bound", bound, "");
        if (strcmp(bound, "y") == 0 || strcmp(bound, "1") == 0) {
            klog("m462 IRadio skip setRadioPower — Phone bound (do not steal)");
            property_set("sys.talkman.helper_rp", "skip");
            radio.clear();
            klog("m467 IRadio drop service after power-skip — did not destroy Phone callbacks");
            return 9;
        }
        klog("m462 IRadio setRadioPower own callbacks — Phone down (SET_UICC pattern)");
    }
    sp<RadioRsp> rsp = new RadioRsp();
    sp<RadioInd> ind = new RadioInd();
    Return<void> sr = radio->setResponseFunctions(rsp, ind);
    if (!sr.isOk()) {
        klog("m349 IRadio setResponseFunctions failed");
        if (want_power) {
            klog("m462 IRadio setResponseFunctions failed");
            property_set("sys.talkman.helper_rp", "n");
        }
        release_iradio(radio, want_power ? "power-srf-fail" : "srf-fail");
        return 3;
    }
    klog("m349 IRadio setResponseFunctions ok");
    if (want_card) {
        int crc = do_card_peek(radio, rsp, 1380);
        release_iradio(radio, "peek");
        return crc;
    }
    int prc = do_set_radio_power(radio, rsp, want_power);
    release_iradio(radio, want_power ? "power" : "default-power");
    return prc;
}
