#include "boothcontroller.h"

#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QImageReader>
#include <QPainter>
#include <QtConcurrent>

namespace {

// Capped so filter re-renders stay snap-fast on the review screen. The
// final print is rendered separately from the full-resolution original.
constexpr int kPreviewMaxDimension = 1600;

// Decodes straight at preview size when the file is larger — the JPEG
// decoder can skip most of the work, much cheaper than a full 24MP decode
// followed by a downscale.
QImage loadPreview(const QString &path)
{
    QImageReader reader(path);
    reader.setAutoTransform(true);
    const QSize size = reader.size();
    if (size.isValid() && (size.width() > kPreviewMaxDimension || size.height() > kPreviewMaxDimension))
        reader.setScaledSize(size.scaled(kPreviewMaxDimension, kPreviewMaxDimension, Qt::KeepAspectRatio));
    return reader.read();
}

QImage applyNoir(QImage image)
{
    image = image.convertToFormat(QImage::Format_RGB32);
    for (int y = 0; y < image.height(); ++y) {
        QRgb *line = reinterpret_cast<QRgb *>(image.scanLine(y));
        for (int x = 0; x < image.width(); ++x) {
            const int gray = qGray(line[x]);
            line[x] = qRgb(gray, gray, gray);
        }
    }
    return image;
}

QImage applySepia(QImage image)
{
    image = image.convertToFormat(QImage::Format_RGB32);
    for (int y = 0; y < image.height(); ++y) {
        QRgb *line = reinterpret_cast<QRgb *>(image.scanLine(y));
        for (int x = 0; x < image.width(); ++x) {
            const QRgb px = line[x];
            const int r = qRed(px);
            const int g = qGreen(px);
            const int b = qBlue(px);
            const int outR = qBound(0, qRound(0.393 * r + 0.769 * g + 0.189 * b), 255);
            const int outG = qBound(0, qRound(0.349 * r + 0.686 * g + 0.168 * b), 255);
            const int outB = qBound(0, qRound(0.272 * r + 0.534 * g + 0.131 * b), 255);
            line[x] = qRgb(outR, outG, outB);
        }
    }
    return image;
}

// HSV saturation x1.5 (capped at full saturation) with hue and value kept,
// done directly in RGB: with V = max channel, each channel's distance from V
// scales with S, so c' = V - (V - c) * k. Capping k at V / (V - min) is the
// S <= 1 cap. Same result as a QColor HSV round-trip (within rounding),
// without converting every pixel through QColor.
QImage applyVivid(QImage image)
{
    image = image.convertToFormat(QImage::Format_RGB32);
    for (int y = 0; y < image.height(); ++y) {
        QRgb *line = reinterpret_cast<QRgb *>(image.scanLine(y));
        for (int x = 0; x < image.width(); ++x) {
            const QRgb px = line[x];
            const int r = qRed(px), g = qGreen(px), b = qBlue(px);
            const int maxC = qMax(r, qMax(g, b));
            const int minC = qMin(r, qMin(g, b));
            if (maxC == minC)
                continue; // gray: no saturation to boost
            const float k = qMin(1.5f, float(maxC) / float(maxC - minC));
            line[x] = qRgb(maxC - qRound((maxC - r) * k), maxC - qRound((maxC - g) * k), maxC - qRound((maxC - b) * k));
        }
    }
    return image;
}

QImage applyFilter(const QImage &image, BoothController::PhotoFilter filter)
{
    switch (filter) {
    case BoothController::Noir: return applyNoir(image);
    case BoothController::Sepia: return applySepia(image);
    case BoothController::Vivid: return applyVivid(image);
    case BoothController::Original: break;
    }
    return image;
}

// Scales to cover `size` then center-crops to exactly `size`.
QImage coverCrop(const QImage &source, const QSize &size)
{
    const QImage scaled = source.scaled(size, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
    return scaled.copy((scaled.width() - size.width()) / 2, (scaled.height() - size.height()) / 2, size.width(),
                       size.height());
}

// --- Final print rendering ---------------------------------------------------
// 300 DPI, laid out like PrintPreview.qml:
//   ClassicStrips: 4x6" portrait sheet (1200x1800) holding two identical
//                  2x6" strips side by side, to be cut down the middle
//   Postcard:      4x6" landscape (1800x1200), one photo + caption band
//   FourUp:        4x6" landscape (1800x1200), 2x2 grid
// Every cell shows the same photo until multi-shot capture exists.

const QColor kPaper(Qt::white);
const QColor kInk(0x2A, 0x25, 0x1D);

struct PrintLayout {
    QSize page;
    QList<QRect> cells;
    QList<QRect> captions;
};

PrintLayout printLayout(BoothController::PrintFormat format)
{
    PrintLayout layout;
    switch (format) {
    case BoothController::ClassicStrips: {
        layout.page = QSize(1200, 1800);
        const int pad = 40, gap = 24, cellW = 600 - 2 * pad, cellH = cellW * 68 / 100;
        for (int strip = 0; strip < 2; ++strip) {
            const int x = strip * 600 + pad;
            for (int i = 0; i < 4; ++i)
                layout.cells.append(QRect(x, pad + i * (cellH + gap), cellW, cellH));
            const int captionTop = pad + 4 * cellH + 3 * gap;
            layout.captions.append(QRect(x, captionTop, cellW, 1800 - pad - captionTop));
        }
        break;
    }
    case BoothController::Postcard: {
        layout.page = QSize(1800, 1200);
        const int pad = 60, captionH = 170;
        layout.cells.append(QRect(pad, pad, 1800 - 2 * pad, 1200 - pad - captionH));
        layout.captions.append(QRect(pad, 1200 - captionH, 1800 - 2 * pad, captionH));
        break;
    }
    case BoothController::FourUp: {
        layout.page = QSize(1800, 1200);
        const int pad = 60, gap = 30;
        const int cellW = (1800 - 2 * pad - gap) / 2, cellH = (1200 - 2 * pad - gap) / 2;
        for (int i = 0; i < 4; ++i)
            layout.cells.append(QRect(pad + (i % 2) * (cellW + gap), pad + (i / 2) * (cellH + gap), cellW, cellH));
        break;
    }
    }
    return layout;
}

QImage renderPrint(const QString &sourcePath, const QImage &fallback, BoothController::PhotoFilter filter,
                   BoothController::PrintFormat format, const QString &caption)
{
    const PrintLayout layout = printLayout(format);
    const QSize cellSize = layout.cells.first().size(); // all cells of a layout are the same size

    // Decode the original straight at (roughly) cell resolution — much
    // faster than a full 24MP decode — then filter once, at that size.
    QImageReader reader(sourcePath);
    reader.setAutoTransform(true);
    if (reader.size().isValid())
        reader.setScaledSize(reader.size().scaled(cellSize, Qt::KeepAspectRatioByExpanding));
    QImage source = reader.read();
    if (source.isNull())
        source = fallback;
    if (source.isNull())
        return QImage();
    const QImage photo = applyFilter(coverCrop(source, cellSize), filter);

    QImage page(layout.page, QImage::Format_RGB32);
    page.fill(kPaper);
    QPainter painter(&page);
    painter.setRenderHint(QPainter::Antialiasing);
    painter.setRenderHint(QPainter::TextAntialiasing);
    for (const QRect &cell : layout.cells)
        painter.drawImage(cell, photo);

    QFont font(QStringLiteral("Instrument Serif"));
    font.setPixelSize(format == BoothController::ClassicStrips ? 44 : 52);
    font.setLetterSpacing(QFont::AbsoluteSpacing, 2);
    painter.setFont(font);
    painter.setPen(kInk);
    for (const QRect &rect : layout.captions)
        painter.drawText(rect, Qt::AlignCenter | Qt::TextWordWrap, caption);
    painter.end();
    return page;
}

QString formatSlug(BoothController::PrintFormat format)
{
    switch (format) {
    case BoothController::ClassicStrips: return QStringLiteral("strips");
    case BoothController::Postcard: return QStringLiteral("postcard");
    case BoothController::FourUp: return QStringLiteral("fourup");
    }
    return QStringLiteral("print");
}

constexpr int kThumbnailSize = 220;

// Scales to cover a kThumbnailSize square then center-crops, matching the
// FilterSelect screen's square thumbnail row.
QImage squareThumbnail(const QImage &source)
{
    if (source.isNull())
        return source;
    const QImage scaled = source.scaled(kThumbnailSize, kThumbnailSize, Qt::KeepAspectRatioByExpanding,
                                         Qt::SmoothTransformation);
    const QRect crop((scaled.width() - kThumbnailSize) / 2, (scaled.height() - kThumbnailSize) / 2, kThumbnailSize,
                      kThumbnailSize);
    return scaled.copy(crop);
}

} // namespace

BoothController::BoothController(CameraSource *source, QObject *parent)
    : QObject(parent)
    , m_source(source)
{
    connect(m_source, &CameraSource::connected, this, [this] {
        setStatusMessage("Connected, starting live view...");
    });

    connect(m_source, &CameraSource::disconnected, this, [this] {
        cancelCountdown();
        setState(Idle);
        setStatusMessage(QString());
    });

    connect(m_source, &CameraSource::errorOccurred, this, [this](CameraError error, const QString &message) {
        // Capture/parameter errors don't mean the connection is gone — stay
        // in LiveView and just surface the message. Anything else (lost
        // connection, camera busy while connecting, ...) drops back to Idle.
        if (error != CameraError::CaptureFailed && error != CameraError::ParameterRejected) {
            cancelCountdown();
            setState(Idle);
        }
        setStatusMessage("Error: " + message);
    });

    connect(m_source, &CameraSource::imageCaptured, this, [this](const QString &path) {
        m_source->stopLiveView();
        discardOriginal(); // a previous shot this session that never ended
        m_capturedImagePath = path;
        emit capturedImagePathChanged();
        m_finalImagePath.clear();
        emit finalImagePathChanged();
        // Decode + filter previews on a worker thread; Review opens when
        // they're ready (m_prepareWatcher below).
        setProcessing(true);
        m_preparingGeneration = m_captureGeneration;
        m_prepareWatcher.setFuture(QtConcurrent::run(&BoothController::preparePhoto, path));
    });

    connect(&m_prepareWatcher, &QFutureWatcher<PreparedPhoto>::finished, this, [this] {
        setProcessing(false);
        if (m_preparingGeneration != m_captureGeneration || m_state != LiveView)
            return; // the session ended (Exit) while the photo was being prepared

        const PreparedPhoto photo = m_prepareWatcher.result();
        if (photo.preview.isNull()) {
            setStatusMessage("Error: could not read the captured photo " + m_capturedImagePath);
            return;
        }
        m_capturedImage = photo.preview;
        for (int i = 0; i < 4; ++i)
            m_filteredPreviews[i] = photo.filtered[i];
        m_filter = Original; // start each new photo unfiltered
        emit filterChanged();
        renderCurrentFilter();
        emit thumbnailsReady(photo.thumbs[Original], photo.thumbs[Noir], photo.thumbs[Sepia], photo.thumbs[Vivid]);
        setState(Review);
        setStatusMessage(QString());
        emit imageCaptured(m_capturedImagePath);
    });

    m_countdownTimer.setInterval(1000);
    connect(&m_countdownTimer, &QTimer::timeout, this, [this] {
        setCountdownValue(m_countdownValue - 1);
        if (m_countdownValue <= 0) {
            m_countdownTimer.stop();
            capture();
        }
    });
}

void BoothController::startLiveView()
{
    if (m_state != Idle)
        return;

    setState(Connecting);
    setStatusMessage("Connecting...");

    if (!m_source->connectToDevice()) {
        // errorOccurred() (connected above) already reset state/message.
        return;
    }

    if (!m_source->startLiveView()) {
        setState(Idle);
        setStatusMessage("Connected, but failed to start live view");
        return;
    }

    setState(LiveView);
    setStatusMessage(QString("Live view running (%1)").arg(m_source->deviceName()));
}

void BoothController::capture()
{
    if (m_state != LiveView)
        return;

    m_source->capture();
}

void BoothController::startCapture()
{
    if (m_state != LiveView || m_countdownValue != 0 || m_processing)
        return;

    setCountdownValue(3);
    m_countdownTimer.start();
}

void BoothController::goIdle()
{
    ++m_captureGeneration;
    discardOriginal();
    cancelCountdown();
    m_source->stopLiveView();
    m_source->disconnectFromDevice();
    setState(Idle);
    setStatusMessage(QString());
}

void BoothController::setState(State state)
{
    if (m_state == state)
        return;
    m_state = state;
    emit stateChanged();
}

void BoothController::setStatusMessage(const QString &message)
{
    if (m_statusMessage == message)
        return;
    m_statusMessage = message;
    emit statusMessageChanged();
}

void BoothController::setCountdownValue(int value)
{
    if (m_countdownValue == value)
        return;
    m_countdownValue = value;
    emit countdownValueChanged();
}

void BoothController::cancelCountdown()
{
    m_countdownTimer.stop();
    setCountdownValue(0);
}

void BoothController::openFilterSelect()
{
    if (m_state != Review)
        return;
    m_filterBeforeSelect = m_filter;
    setState(FilterSelect);
}

void BoothController::confirmFilterSelect()
{
    openFormatSelect();
}

void BoothController::cancelFilterSelect()
{
    if (m_state != FilterSelect)
        return;
    setFilter(m_filterBeforeSelect);
    setState(Review);
}

void BoothController::chooseFilter(PhotoFilter filter)
{
    if (m_state != FilterSelect)
        return;
    setFilter(filter);
}

void BoothController::setFilter(PhotoFilter filter)
{
    if (m_filter == filter)
        return;
    m_filter = filter;
    emit filterChanged();
    renderCurrentFilter();
}

void BoothController::renderCurrentFilter()
{
    if (m_capturedImage.isNull())
        return;

    // Precomputed by preparePhoto(), so switching filters costs nothing.
    const QImage &filtered = m_filteredPreviews[m_filter];
    emit photoFrameReady(filtered.isNull() ? applyFilter(m_capturedImage, m_filter) : filtered);
}

void BoothController::setProcessing(bool processing)
{
    if (m_processing == processing)
        return;
    m_processing = processing;
    emit processingChanged();
}

// Runs on a worker thread (QtConcurrent) — touches no members.
BoothController::PreparedPhoto BoothController::preparePhoto(const QString &path)
{
    PreparedPhoto photo;
    photo.preview = loadPreview(path).convertToFormat(QImage::Format_RGB32);
    if (photo.preview.isNull())
        return photo;
    const QImage thumb = squareThumbnail(photo.preview);
    for (int f = Original; f <= Vivid; ++f) {
        photo.filtered[f] = applyFilter(photo.preview, PhotoFilter(f));
        photo.thumbs[f] = applyFilter(thumb, PhotoFilter(f));
    }
    return photo;
}

void BoothController::discardOriginal()
{
    if (m_capturedImagePath.isEmpty())
        return;
    QFile::remove(m_capturedImagePath);
    m_capturedImagePath.clear();
    emit capturedImagePathChanged();
}

void BoothController::setPrinterReady(bool ready)
{
    if (m_printerReady == ready)
        return;
    m_printerReady = ready;
    emit printerReadyChanged();
}

void BoothController::openFormatSelect()
{
    if (m_state != FilterSelect && m_state != Share)
        return;
    if (m_printFormat != ClassicStrips) {
        m_printFormat = ClassicStrips;
        emit printFormatChanged();
    }
    setCopies(1);
    setState(FormatSelect);
}

void BoothController::closeFormatSelect()
{
    if (m_state != FormatSelect)
        return;
    setState(FilterSelect);
}

void BoothController::choosePrintFormat(PrintFormat format)
{
    if (m_state != FormatSelect || m_printFormat == format)
        return;
    m_printFormat = format;
    emit printFormatChanged();
}

void BoothController::setCopies(int copies)
{
    copies = qBound(1, copies, maxCopies());
    if (m_copies == copies)
        return;
    m_copies = copies;
    emit copiesChanged();
}

void BoothController::requestPrint(const QString &caption)
{
    if (m_state != FormatSelect)
        return;

    const QImage print = renderPrint(m_capturedImagePath, m_capturedImage, m_filter, m_printFormat, caption);
    // Saved next to the original, named after it plus the layout, e.g.
    // 20261001_084749_932_strips.jpg (a second print of another layout
    // gets its own file).
    const QFileInfo original(m_capturedImagePath);
    const QString path = original.dir().filePath(original.completeBaseName() + '_' + formatSlug(m_printFormat)
                                                 + QStringLiteral(".jpg"));
    if (print.isNull() || !print.save(path, "JPG", 95)) {
        setStatusMessage("Error: could not save the print image to " + path);
        return;
    }

    m_finalImagePath = path;
    emit finalImagePathChanged();
    emit printRequested(m_finalImagePath, m_copies);
    setState(Share);
}

QString BoothController::shareUrl() const
{
    QString base = qEnvironmentVariable("PHOTOBOOTH_SHARE_BASE_URL");
    if (base.isEmpty() || m_finalImagePath.isEmpty())
        return QString();
    while (base.endsWith('/'))
        base.chop(1);
    return base + '/' + QFileInfo(m_finalImagePath).fileName();
}

void BoothController::printAnother()
{
    if (m_state != Share)
        return;
    openFormatSelect();
}

void BoothController::retake()
{
    if (m_state != Share)
        return;
    goIdle();
    startLiveView();
}

void BoothController::finish()
{
    goIdle();
}

void BoothController::requestShare(const QString &channel)
{
    if (m_state != Share)
        return;
    emit shareRequested(channel, m_finalImagePath, shareUrl());
}
