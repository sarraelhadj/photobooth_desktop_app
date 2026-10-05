#include "qrcodeitem.h"

#include <QPainter>

#include <qrencode.h>

namespace {
constexpr int kQuietZoneModules = 2;
}

QrCodeItem::QrCodeItem(QQuickItem *parent)
    : QQuickPaintedItem(parent)
{
}

void QrCodeItem::setText(const QString &text)
{
    if (m_text == text)
        return;
    m_text = text;

    m_size = 0;
    m_modules.clear();
    if (!m_text.isEmpty()) {
        const QByteArray utf8 = m_text.toUtf8();
        if (QRcode *code = QRcode_encodeString(utf8.constData(), 0, QR_ECLEVEL_M, QR_MODE_8, 1)) {
            m_size = code->width;
            m_modules.resize(m_size * m_size);
            for (int i = 0; i < m_size * m_size; ++i)
                m_modules[i] = code->data[i] & 0x1; // bit 0 = dark module
            QRcode_free(code);
        }
    }

    emit textChanged();
    update();
}

void QrCodeItem::setDarkColor(const QColor &color)
{
    if (m_darkColor == color)
        return;
    m_darkColor = color;
    emit colorsChanged();
    update();
}

void QrCodeItem::setLightColor(const QColor &color)
{
    if (m_lightColor == color)
        return;
    m_lightColor = color;
    emit colorsChanged();
    update();
}

void QrCodeItem::paint(QPainter *painter)
{
    painter->fillRect(boundingRect(), m_lightColor);
    if (m_size == 0)
        return;

    const int totalModules = m_size + 2 * kQuietZoneModules;
    const int moduleSize = qMax(1, int(qMin(width(), height())) / totalModules);
    const int codeSize = moduleSize * m_size;
    const int x0 = (int(width()) - codeSize) / 2;
    const int y0 = (int(height()) - codeSize) / 2;

    for (int y = 0; y < m_size; ++y) {
        for (int x = 0; x < m_size; ++x) {
            if (m_modules[y * m_size + x])
                painter->fillRect(x0 + x * moduleSize, y0 + y * moduleSize, moduleSize, moduleSize, m_darkColor);
        }
    }
}
