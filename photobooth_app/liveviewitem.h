#pragma once

#include <QImage>
#include <QQuickPaintedItem>

// Paints whatever QImage was last handed to it via setFrame(), letterboxed
// to fit the item's size (or, with cropToFill, scaled to cover it and
// center-cropped — used by the print-layout previews), clipped to `radius`
// rounded corners. main.cpp connects CameraSource::frameReady
// directly to setFrame() once the QML tree exists — no per-frame QML
// property bindings, just a plain Qt signal/slot at live-view frame rate.
class LiveViewItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(bool cropToFill READ cropToFill WRITE setCropToFill NOTIFY cropToFillChanged)
    Q_PROPERTY(qreal radius READ radius WRITE setRadius NOTIFY radiusChanged)
public:
    explicit LiveViewItem(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    bool cropToFill() const { return m_cropToFill; }
    void setCropToFill(bool crop);
    qreal radius() const { return m_radius; }
    void setRadius(qreal radius);

signals:
    void cropToFillChanged();
    void radiusChanged();

public slots:
    void setFrame(const QImage &frame);

private:
    QImage m_frame;
    bool m_cropToFill = false;
    qreal m_radius = 0;
};
