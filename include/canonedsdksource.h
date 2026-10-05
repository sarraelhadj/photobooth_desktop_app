#pragma once

#include "camerasource.h"
#include <EDSDK.h>
#include <QMutex>
#include <QTimer>

// CanonEdsdkSource: Canon EDSDK (USB) implementation of CameraSource.
//
// EDSDK is callback/event driven and not thread-safe: all EdsXxx calls must
// happen on the thread EdsInitializeSDK() was called on. This class
// currently runs entirely on the caller's (UI) thread — see the threading
// note at the end of canonedsdksource.cpp.
class CanonEdsdkSource : public CameraSource
{
    Q_OBJECT
public:
    explicit CanonEdsdkSource(QObject *parent = nullptr);
    ~CanonEdsdkSource() override;

    bool connectToDevice() override;
    void disconnectFromDevice() override;
    bool isConnected() const override;

    bool startLiveView() override;
    void stopLiveView() override;

    void capture() override;

    void setParameter(CameraParam param, const QVariant &value) override;
    QVariant parameter(CameraParam param) const override;

    QString deviceName() const override;

private:
    // EDSDK callback trampolines: EDSDK calls these with a raw context
    // pointer, which is `this`, and they dispatch back into the instance.
    static EdsError EDSCALLBACK handleObjectEvent(EdsObjectEvent event, EdsBaseRef object, EdsVoid *context);
    static EdsError EDSCALLBACK handlePropertyEvent(EdsPropertyEvent event, EdsPropertyID property,
                                                       EdsUInt32 param, EdsVoid *context);
    static EdsError EDSCALLBACK handleStateEvent(EdsStateEvent event, EdsUInt32 param, EdsVoid *context);

    void onObjectEvent(EdsObjectEvent event, EdsBaseRef object);
    void onStateEvent(EdsStateEvent event, EdsUInt32 param);

    void downloadImage(EdsDirectoryItemRef directoryItem);
    void pollLiveViewFrame(); // driven by m_liveViewTimer

    EdsCameraRef m_camera = nullptr;
    bool m_sdkInitialized = false;
    bool m_sessionOpen = false;
    bool m_liveViewActive = false;

    // EDSDK has no "frame arrived" callback for live view: frames are
    // pulled with EdsDownloadEvfImage on this timer.
    QTimer m_liveViewTimer;

    // On Linux/Mac, EDSDK queues object/state/property events (e.g. the
    // DirItemRequestTransfer that fires after TakePicture, telling us to
    // download the shot) but never dispatches them on its own — EdsGetEvent()
    // has to be polled regularly for handleObjectEvent()/handleStateEvent()
    // to ever run. Runs for the lifetime of the session, independent of
    // live view, since state events (camera unplugged) matter either way.
    QTimer m_eventTimer;

    QString m_downloadDir;    // where captured full-res images land
};
