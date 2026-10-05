#pragma once

#include <QColor>
#include <QQuickPaintedItem>
#include <QString>
#include <QVector>

// Paints `text` as a QR code (via libqrencode), centered and scaled to
// whole-pixel modules so it stays crisp and scannable, with the standard
// quiet zone around it. Paints nothing when `text` is empty or can't be
// encoded — `valid` tells QML which case it's in.
class QrCodeItem : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)
    Q_PROPERTY(QColor darkColor READ darkColor WRITE setDarkColor NOTIFY colorsChanged)
    Q_PROPERTY(QColor lightColor READ lightColor WRITE setLightColor NOTIFY colorsChanged)
    Q_PROPERTY(bool valid READ valid NOTIFY textChanged)

public:
    explicit QrCodeItem(QQuickItem *parent = nullptr);

    void paint(QPainter *painter) override;

    QString text() const { return m_text; }
    void setText(const QString &text);
    QColor darkColor() const { return m_darkColor; }
    void setDarkColor(const QColor &color);
    QColor lightColor() const { return m_lightColor; }
    void setLightColor(const QColor &color);
    bool valid() const { return m_size > 0; }

signals:
    void textChanged();
    void colorsChanged();

private:
    QString m_text;
    QColor m_darkColor = Qt::black;
    QColor m_lightColor = Qt::white;
    int m_size = 0;          // modules per side, 0 = nothing encoded
    QVector<bool> m_modules; // m_size * m_size, row-major, true = dark
};
