#include "canonedsdksource.h"
#include "edserrorstring.h"
#include <QDateTime>
#include <QDir>
#include <QStandardPaths>

CanonEdsdkSource::CanonEdsdkSource(QObject *parent)
    : CameraSource(parent)
{
    m_downloadDir = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation)
                    + "/photobooth";
    QDir().mkpath(m_downloadDir);

    // Live view is pull-based in EDSDK. The achievable frame rate depends on
    // the camera body; liveview_app reports the delivered FPS.
    connect(&m_liveViewTimer, &QTimer::timeout, this, &CanonEdsdkSource::pollLiveViewFrame);
    m_liveViewTimer.setInterval(50);

    connect(&m_eventTimer, &QTimer::timeout, this, [] { EdsGetEvent(); });
    m_eventTimer.setInterval(50);
}

CanonEdsdkSource::~CanonEdsdkSource()
{
    disconnectFromDevice();
    if (m_sdkInitialized)
        EdsTerminateSDK();
}

bool CanonEdsdkSource::connectToDevice()
{
    if (!m_sdkInitialized) {
        EdsError err = EdsInitializeSDK();
        if (err != EDS_ERR_OK) {
            emit errorOccurred(CameraError::Unknown, "EdsInitializeSDK failed: " + edsErrorToString(err));
            return false;
        }
        m_sdkInitialized = true;
    }

    EdsCameraListRef cameraList = nullptr;
    EdsError err = EdsGetCameraList(&cameraList);
    if (err != EDS_ERR_OK) {
        emit errorOccurred(CameraError::ConnectionLost, "EdsGetCameraList failed: " + edsErrorToString(err));
        return false;
    }

    EdsUInt32 count = 0;
    EdsGetChildCount(cameraList, &count);
    if (count == 0) {
        EdsRelease(cameraList);
        emit errorOccurred(CameraError::ConnectionLost, "No camera detected on USB");
        return false;
    }

    // TODO: with several cameras attached, let the operator pick one (or
    // match a serial number) instead of taking the first.
    err = EdsGetChildAtIndex(cameraList, 0, &m_camera);
    if (err != EDS_ERR_OK) {
        EdsRelease(cameraList);
        emit errorOccurred(CameraError::ConnectionLost, "EdsGetChildAtIndex failed: " + edsErrorToString(err));
        return false;
    }
    EdsRelease(cameraList);

    EdsSetObjectEventHandler(m_camera, kEdsObjectEvent_All, &CanonEdsdkSource::handleObjectEvent, this);
    EdsSetPropertyEventHandler(m_camera, kEdsPropertyEvent_All, &CanonEdsdkSource::handlePropertyEvent, this);
    EdsSetCameraStateEventHandler(m_camera, kEdsStateEvent_All, &CanonEdsdkSource::handleStateEvent, this);

    err = EdsOpenSession(m_camera);
    if (err != EDS_ERR_OK) {
        emit errorOccurred(CameraError::ConnectionLost, "EdsOpenSession failed: " + edsErrorToString(err));
        return false;
    }
    m_sessionOpen = true;

    // Save to host PC, not camera card — required for live view + tethered
    // capture workflows.
    EdsUInt32 saveTo = kEdsSaveTo_Host;
    EdsSetPropertyData(m_camera, kEdsPropID_SaveTo, 0, sizeof(saveTo), &saveTo);

    // Required alongside SaveTo=Host: tells the camera how much host disk
    // space is available. Skipping this leaves the camera's internal
    // capacity counter at zero, which on many EOS bodies surfaces as a
    // bogus storage error (e.g. EDS_ERR_TAKE_PICTURE_CARD_NG) on capture()
    // even with a perfectly good card inserted. Values match Canon's own
    // EDSDK sample (CameraModel.cpp).
    EdsCapacity capacity = {0x7FFFFFFF, 0x1000, 1};
    EdsSetCapacity(m_camera, capacity);

    m_eventTimer.start();

    emit connected();
    return true;
}

void CanonEdsdkSource::disconnectFromDevice()
{
    m_eventTimer.stop();
    stopLiveView();
    if (m_sessionOpen && m_camera) {
        EdsCloseSession(m_camera);
        m_sessionOpen = false;
    }
    if (m_camera) {
        EdsRelease(m_camera);
        m_camera = nullptr;
    }
    emit disconnected();
}

bool CanonEdsdkSource::isConnected() const
{
    return m_sessionOpen;
}

bool CanonEdsdkSource::startLiveView()
{
    if (!m_sessionOpen)
        return false;

    EdsUInt32 device = kEdsEvfOutputDevice_PC;
    EdsError err = EdsSetPropertyData(m_camera, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device);
    if (err != EDS_ERR_OK) {
        emit errorOccurred(CameraError::Unknown, "Failed to enable EVF output to PC: " + edsErrorToString(err));
        return false;
    }

    m_liveViewActive = true;
    m_liveViewTimer.start();
    return true;
}

void CanonEdsdkSource::stopLiveView()
{
    if (!m_liveViewActive)
        return;
    m_liveViewTimer.stop();
    m_liveViewActive = false;

    if (m_camera) {
        EdsUInt32 device = kEdsEvfOutputDevice_TFT; // back to camera screen
        EdsSetPropertyData(m_camera, kEdsPropID_Evf_OutputDevice, 0, sizeof(device), &device);
    }
}

void CanonEdsdkSource::pollLiveViewFrame()
{
    EdsStreamRef stream = nullptr;
    EdsEvfImageRef evfImage = nullptr;

    if (EdsCreateMemoryStream(0, &stream) != EDS_ERR_OK)
        return;
    if (EdsCreateEvfImageRef(stream, &evfImage) != EDS_ERR_OK) {
        EdsRelease(stream);
        return;
    }

    EdsError err = EdsDownloadEvfImage(m_camera, evfImage);
    if (err == EDS_ERR_OK) {
        EdsUInt64 length = 0;
        EdsGetLength(stream, &length);
        EdsVoid *data = nullptr;
        EdsGetPointer(stream, &data);

        QImage frame;
        if (frame.loadFromData(reinterpret_cast<const uchar *>(data), static_cast<int>(length), "JPG"))
            emit frameReady(frame);
        // Non-fatal decode failures happen occasionally (partial frame
        // mid-transfer) — drop the frame rather than surfacing an error,
        // the next tick will usually succeed.
    } else if (err == EDS_ERR_OBJECT_NOTREADY) {
        // Camera not ready yet (e.g. still processing) — expected, ignore.
    } else {
        emit errorOccurred(CameraError::ConnectionLost, "Live view download failed: " + edsErrorToString(err));
    }

    EdsRelease(evfImage);
    EdsRelease(stream);
}

void CanonEdsdkSource::capture()
{
    if (!m_sessionOpen) {
        emit errorOccurred(CameraError::DeviceBusy, "Camera not connected");
        return;
    }
    // The actual image arrives asynchronously via handleObjectEvent()
    // (kEdsObjectEvent_DirItemRequestTransfer) once the camera finishes
    // writing/processing the shot — capture() itself just triggers it.
    EdsError err = EdsSendCommand(m_camera, kEdsCameraCommand_TakePicture, 0);
    if (err != EDS_ERR_OK)
        emit errorOccurred(CameraError::CaptureFailed,
                            "EdsSendCommand(TakePicture) failed: " + edsErrorToString(err));
}

EdsError EDSCALLBACK CanonEdsdkSource::handleObjectEvent(EdsObjectEvent event, EdsBaseRef object, EdsVoid *context)
{
    auto *self = static_cast<CanonEdsdkSource *>(context);
    if (self)
        self->onObjectEvent(event, object);
    return EDS_ERR_OK;
}

void CanonEdsdkSource::onObjectEvent(EdsObjectEvent event, EdsBaseRef object)
{
    if (event == kEdsObjectEvent_DirItemRequestTransfer) {
        downloadImage(static_cast<EdsDirectoryItemRef>(object));
    } else if (object) {
        EdsRelease(object);
    }
    // On Linux, object events are dispatched from EdsGetEvent(), i.e. on the
    // thread polling m_eventTimer — see the threading note at the end.
}

void CanonEdsdkSource::downloadImage(EdsDirectoryItemRef directoryItem)
{
    EdsDirectoryItemInfo info;
    EdsError err = EdsGetDirectoryItemInfo(directoryItem, &info);
    if (err != EDS_ERR_OK) {
        EdsRelease(directoryItem);
        emit errorOccurred(CameraError::CaptureFailed, "EdsGetDirectoryItemInfo failed: " + edsErrorToString(err));
        return;
    }

    const QString fileName = QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss_zzz") + ".jpg";
    const QString fullPath = m_downloadDir + "/" + fileName;

    EdsStreamRef stream = nullptr;
    EdsCreateFileStream(fullPath.toUtf8().constData(),
                         kEdsFileCreateDisposition_CreateAlways,
                         kEdsAccess_ReadWrite, &stream);

    err = EdsDownload(directoryItem, info.size, stream);
    if (err == EDS_ERR_OK) {
        EdsDownloadComplete(directoryItem);
        emit imageCaptured(fullPath);
    } else {
        emit errorOccurred(CameraError::CaptureFailed, "EdsDownload failed: " + edsErrorToString(err));
    }

    EdsRelease(stream);
    EdsRelease(directoryItem);
}

EdsError EDSCALLBACK CanonEdsdkSource::handlePropertyEvent(EdsPropertyEvent, EdsPropertyID, EdsUInt32, EdsVoid *)
{
    // TODO: react to settings changed on the camera body (e.g. a dial).
    return EDS_ERR_OK;
}

EdsError EDSCALLBACK CanonEdsdkSource::handleStateEvent(EdsStateEvent event, EdsUInt32 param, EdsVoid *context)
{
    auto *self = static_cast<CanonEdsdkSource *>(context);
    if (self)
        self->onStateEvent(event, param);
    return EDS_ERR_OK;
}

void CanonEdsdkSource::onStateEvent(EdsStateEvent event, EdsUInt32 /*param*/)
{
    if (event == kEdsStateEvent_Shutdown) {
        m_sessionOpen = false;
        emit errorOccurred(CameraError::ConnectionLost, "Camera powered off or unplugged");
        emit disconnected();
    }
}

void CanonEdsdkSource::setParameter(CameraParam param, const QVariant &value)
{
    if (!m_sessionOpen)
        return;

    // TODO: only ISO is mapped so far. Aperture, shutter speed, white
    // balance and AF mode need their EDSDK property IDs, and all of them a
    // lookup table: EDSDK uses opaque per-model codes for ISO/Av/Tv values,
    // not human-readable numbers.
    switch (param) {
    case CameraParam::Iso: {
        EdsUInt32 isoValue = value.toUInt(); // raw EDSDK ISO code
        EdsSetPropertyData(m_camera, kEdsPropID_ISOSpeed, 0, sizeof(isoValue), &isoValue);
        break;
    }
    default:
        emit errorOccurred(CameraError::ParameterRejected, "Parameter not yet mapped");
        return;
    }
    emit parameterChanged(param, value);
}

QVariant CanonEdsdkSource::parameter(CameraParam param) const
{
    if (!m_sessionOpen || !m_camera)
        return {};

    if (param == CameraParam::Iso) {
        EdsUInt32 isoValue = 0;
        EdsGetPropertyData(m_camera, kEdsPropID_ISOSpeed, 0, sizeof(isoValue), &isoValue);
        return isoValue; // raw EDSDK ISO code, not an ISO number
    }
    return {};
}

QString CanonEdsdkSource::deviceName() const
{
    if (!m_camera)
        return QString();
    EdsDeviceInfo info;
    EdsGetDeviceInfo(m_camera, &info);
    return QString::fromLocal8Bit(info.szDeviceDescription);
}

// --- Threading note -------------------------------------------------
// Everything here currently runs on the thread that owns this object (the
// UI thread in both apps), so USB transfers — notably the full-resolution
// download in downloadImage() — block the UI while they run.
// TODO: move this object to a dedicated QThread (moveToThread) and call
// capture()/setParameter()/... through queued connections. EDSDK must then
// be initialized and polled (EdsGetEvent) from that same thread.
