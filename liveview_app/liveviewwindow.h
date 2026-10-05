#pragma once

#include <QElapsedTimer>
#include <QTimer>
#include <QWidget>

#include "canonedsdksource.h"

class QLabel;
class QPushButton;

// Minimal diagnostic window for the EDSDK live-view path: connect to the
// camera, start EVF streaming, paint each frame as it arrives and report the
// delivered frame rate. The guest-facing UI is photobooth_app.
class LiveViewWindow : public QWidget
{
    Q_OBJECT
public:
    explicit LiveViewWindow(QWidget *parent = nullptr);

private slots:
    void onConnectClicked();
    void onFrameReady(const QImage &frame);
    void onError(CameraError error, const QString &message);
    void onConnected();
    void onDisconnected();
    void updateFpsLabel();

private:
    CanonEdsdkSource m_source;
    QLabel *m_videoLabel;
    QLabel *m_statusLabel;
    QLabel *m_fpsLabel;
    QPushButton *m_connectButton;

    // Rolling 1s frame counter: incremented in onFrameReady, read and
    // reset by updateFpsLabel() on m_fpsTimer's 1000ms tick.
    QTimer m_fpsTimer;
    int m_frameCount = 0;
    QElapsedTimer m_lastFrameTimer; // for instantaneous inter-frame gap
    qint64 m_lastFrameIntervalMs = 0;
};
