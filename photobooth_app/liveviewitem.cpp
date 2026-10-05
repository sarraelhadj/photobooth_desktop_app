#include "liveviewitem.h"

#include <QPainter>
#include <QPainterPath>

LiveViewItem::LiveViewItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
}

void LiveViewItem::paint(QPainter *painter)
{
    if (m_radius > 0) {
        QPainterPath clip;
        clip.addRoundedRect(boundingRect(), m_radius, m_radius);
        painter->setRenderHint(QPainter::Antialiasing);
        painter->setClipPath(clip);
    }
    painter->fillRect(boundingRect(), Qt::black);

    if (m_frame.isNull())
        return;

    const QSizeF target = boundingRect().size();
    const QSizeF scaled = m_frame.size().scaled(target.toSize(),
                                                m_cropToFill ? Qt::KeepAspectRatioByExpanding : Qt::KeepAspectRatio);
    const QRectF destRect(
        (target.width() - scaled.width()) / 2.0,
        (target.height() - scaled.height()) / 2.0,
        scaled.width(),
        scaled.height());

    if (m_cropToFill && m_radius <= 0)
        painter->setClipRect(boundingRect());
    painter->drawImage(destRect, m_frame);
}

void LiveViewItem::setRadius(qreal radius)
{
    if (qFuzzyCompare(m_radius, radius))
        return;
    m_radius = radius;
    emit radiusChanged();
    update();
}

void LiveViewItem::setCropToFill(bool crop)
{
    if (m_cropToFill == crop)
        return;
    m_cropToFill = crop;
    emit cropToFillChanged();
    update();
}

void LiveViewItem::setFrame(const QImage &frame)
{
    m_frame = frame;
    update();
}
