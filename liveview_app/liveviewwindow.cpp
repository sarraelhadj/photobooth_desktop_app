#include "liveviewwindow.h"

#include <QLabel>
#include <QPushButton>
#include <QVBoxLayout>

LiveViewWindow::LiveViewWindow(QWidget *parent)
    : QWidget(parent)
{
    setWindowTitle("Canon EDSDK Live View");

    m_videoLabel = new QLabel(this);
    m_videoLabel->setMinimumSize(960, 640);
    m_videoLabel->setAlignment(Qt::AlignCenter);
    m_videoLabel->setStyleSheet("background-color: black; color: white;");
    m_videoLabel->setText("Not connected");

    m_statusLabel = new QLabel("Idle", this);
    m_fpsLabel = new QLabel(this);
    m_connectButton = new QPushButton("Connect && Start Live View", this);

    auto *layout = new QVBoxLayout(this);
    layout->addWidget(m_videoLabel);
    layout->addWidget(m_statusLabel);
    layout->addWidget(m_fpsLabel);
    layout->addWidget(m_connectButton);

    connect(m_connectButton, &QPushButton::clicked, this, &LiveViewWindow::onConnectClicked);
    connect(&m_source, &CameraSource::frameReady, this, &LiveViewWindow::onFrameReady);
    connect(&m_source, &CameraSource::errorOccurred, this, &LiveViewWindow::onError);
    connect(&m_source, &CameraSource::connected, this, &LiveViewWindow::onConnected);
    connect(&m_source, &CameraSource::disconnected, this, &LiveViewWindow::onDisconnected);

    // Recomputed every second from the frame count onFrameReady bumps, so
    // it reads out actual delivered FPS rather than the ~50ms poll-timer
    // interval CanonEdsdkSource requests (those can diverge under load).
    connect(&m_fpsTimer, &QTimer::timeout, this, &LiveViewWindow::updateFpsLabel);
    m_fpsTimer.start(1000);
}

void LiveViewWindow::onConnectClicked()
{
    m_connectButton->setEnabled(false);
    m_statusLabel->setText("Connecting...");

    if (!m_source.connectToDevice()) {
        m_connectButton->setEnabled(true);
        return;
    }

    if (!m_source.startLiveView()) {
        m_statusLabel->setText("Connected, but failed to start live view");
        m_connectButton->setEnabled(true);
        return;
    }

    m_statusLabel->setText(QString("Live view running (%1)").arg(m_source.deviceName()));
}

void LiveViewWindow::onFrameReady(const QImage &frame)
{
    m_videoLabel->setPixmap(QPixmap::fromImage(frame).scaled(
        m_videoLabel->size(), Qt::KeepAspectRatio, Qt::SmoothTransformation));

    ++m_frameCount;
    if (m_lastFrameTimer.isValid())
        m_lastFrameIntervalMs = m_lastFrameTimer.restart();
    else
        m_lastFrameTimer.start();
}

void LiveViewWindow::updateFpsLabel()
{
    const int fps = m_frameCount;
    m_frameCount = 0;
    m_fpsLabel->setText(QString("%1 fps (last frame gap: %2 ms)").arg(fps).arg(m_lastFrameIntervalMs));
}

void LiveViewWindow::onError(CameraError /*error*/, const QString &message)
{
    m_statusLabel->setText("Error: " + message);
    m_connectButton->setEnabled(true);
}

void LiveViewWindow::onConnected()
{
    m_statusLabel->setText("Connected");
}

void LiveViewWindow::onDisconnected()
{
    m_statusLabel->setText("Disconnected");
    m_connectButton->setEnabled(true);
}
