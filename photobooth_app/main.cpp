#include <QDir>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickWindow>
#include <functional>

#include "boothcontroller.h"
#include "canonedsdksource.h"
#include "liveviewitem.h"
#include "qrcodeitem.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Bundled fonts (see Theme.qml) — registered before any QML loads so
    // Theme's family names resolve instead of silently falling back.
    const QDir fontsDir(QStringLiteral(APP_FONTS_DIR));
    for (const QString &file : fontsDir.entryList({QStringLiteral("*.ttf"), QStringLiteral("*.otf")}, QDir::Files)) {
        if (QFontDatabase::addApplicationFont(fontsDir.filePath(file)) < 0)
            qWarning("Failed to load font %s", qPrintable(file));
    }

    qmlRegisterType<LiveViewItem>("Photobooth", 1, 0, "LiveViewItem");
    qmlRegisterType<QrCodeItem>("Photobooth", 1, 0, "QrCodeItem");
    qmlRegisterUncreatableType<BoothController>(
        "Photobooth", 1, 0, "BoothController", "BoothController is created in C++");
    qmlRegisterSingletonType(
        QUrl::fromLocalFile(QStringLiteral(APP_QML_DIR "/Theme.qml")), "Photobooth", 1, 0, "Theme");
    qmlRegisterSingletonType(
        QUrl::fromLocalFile(QStringLiteral(APP_QML_DIR "/Strings.qml")), "Photobooth", 1, 0, "Strings");
    CanonEdsdkSource source;
    BoothController booth(&source);

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("booth", &booth);
    engine.load(QUrl::fromLocalFile(QStringLiteral(APP_QML_DIR "/Main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    // Live view frames, review/filter-select previews and filter
    // thumbnails all go straight from their C++ source to the paint items
    // — no QML binding in the hot path. Found once after the QML tree
    // exists; the screens tag their items with these objectNames.
    QQuickWindow *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (window) {
        if (auto *liveViewItem = window->findChild<LiveViewItem *>("liveViewItem")) {
            QObject::connect(&source, &CameraSource::frameReady, liveViewItem, &LiveViewItem::setFrame);
        }
        if (auto *reviewImageItem = window->findChild<LiveViewItem *>("reviewImageItem")) {
            QObject::connect(&booth, &BoothController::photoFrameReady, reviewImageItem, &LiveViewItem::setFrame);
        }
        if (auto *filterPreviewItem = window->findChild<LiveViewItem *>("filterPreviewItem")) {
            QObject::connect(&booth, &BoothController::photoFrameReady, filterPreviewItem, &LiveViewItem::setFrame);
        }

        auto *thumbOriginal = window->findChild<LiveViewItem *>("thumbOriginal");
        auto *thumbNoir = window->findChild<LiveViewItem *>("thumbNoir");
        auto *thumbSepia = window->findChild<LiveViewItem *>("thumbSepia");
        auto *thumbVivid = window->findChild<LiveViewItem *>("thumbVivid");
        QObject::connect(&booth, &BoothController::thumbnailsReady, window,
                          [=](const QImage &original, const QImage &noir, const QImage &sepia, const QImage &vivid) {
                              if (thumbOriginal)
                                  thumbOriginal->setFrame(original);
                              if (thumbNoir)
                                  thumbNoir->setFrame(noir);
                              if (thumbSepia)
                                  thumbSepia->setFrame(sepia);
                              if (thumbVivid)
                                  thumbVivid->setFrame(vivid);
                          });

        // Print-layout previews (PrintPreview.qml, on the format and share
        // screens): many cells, some Repeater-created, all tagged
        // "printPhoto". Walks the visual item tree since Repeater delegates
        // aren't reliably QObject children that findChildren() would see.
        std::function<void(QQuickItem *)> connectPrintPhotos = [&](QQuickItem *item) {
            if (auto *cell = qobject_cast<LiveViewItem *>(item); cell && item->objectName() == QLatin1String("printPhoto"))
                QObject::connect(&booth, &BoothController::photoFrameReady, cell, &LiveViewItem::setFrame);
            for (QQuickItem *child : item->childItems())
                connectPrintPhotos(child);
        };
        connectPrintPhotos(window->contentItem());
    }

    return app.exec();
}
