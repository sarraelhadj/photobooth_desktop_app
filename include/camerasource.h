#pragma once

#include <QObject>
#include <QImage>
#include <QString>
#include <QVariant>

// CameraSource is the interface everything above the camera layer (UI,
// booth logic) programs against. Nothing above this layer includes a vendor
// SDK header, so a backend (EDSDK today; CCAPI, gPhoto2, ... later) can be
// swapped without touching UI or business logic.

enum class CameraParam {
    Iso,
    Aperture,
    ShutterSpeed,
    WhiteBalance,
    AfMode
};

enum class CameraError {
    ConnectionLost,
    CaptureFailed,
    ParameterRejected,
    DeviceBusy,
    Unknown
};

class CameraSource : public QObject
{
    Q_OBJECT
public:
    explicit CameraSource(QObject *parent = nullptr) : QObject(parent) {}
    virtual ~CameraSource() = default;

    // Lifecycle
    virtual bool connectToDevice() = 0;
    virtual void disconnectFromDevice() = 0;
    virtual bool isConnected() const = 0;

    // Live view: backend pushes frames via frameReady(); UI never polls.
    virtual bool startLiveView() = 0;
    virtual void stopLiveView() = 0;

    // Capture: asynchronous. The result arrives via imageCaptured() or
    // errorOccurred(), never as a return value.
    virtual void capture() = 0;

    // Camera settings. Async for the same reason as capture().
    virtual void setParameter(CameraParam param, const QVariant &value) = 0;
    virtual QVariant parameter(CameraParam param) const = 0;

    // Human-readable identity for the operator console / session log.
    virtual QString deviceName() const = 0;

signals:
    void connected();
    void disconnected();

    // frame: decoded live-view frame.
    void frameReady(const QImage &frame);

    // path: full-resolution image already written to local storage.
    void imageCaptured(const QString &path);

    void parameterChanged(CameraParam param, const QVariant &value);
    void errorOccurred(CameraError error, const QString &message);
};
