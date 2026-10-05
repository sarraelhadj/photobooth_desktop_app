#pragma once

#include <QFutureWatcher>
#include <QImage>
#include <QObject>
#include <QString>
#include <QTimer>

#include "canonedsdksource.h"

// BoothController is what the QML UI programs against: it owns the booth
// state machine and turns guest actions into CameraSource calls. QML never
// touches the camera backend directly.
//
// Flow: Idle -> Connecting -> LiveView -> Review -> FilterSelect ->
// FormatSelect -> Share, moved through with Next and stepped back with
// Back; Exit (goIdle) ends the session from anywhere. The 3-2-1 countdown
// is a sub-state of LiveView (countdownValue > 0), not its own State.
//
// One photo is captured per session for now, so every cell of a
// multi-shot layout (strips, four-up) shows that same photo.
class BoothController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(int countdownValue READ countdownValue NOTIFY countdownValueChanged)
    Q_PROPERTY(bool processing READ processing NOTIFY processingChanged)
    Q_PROPERTY(QString capturedImagePath READ capturedImagePath NOTIFY capturedImagePathChanged)
    Q_PROPERTY(PhotoFilter filter READ filter NOTIFY filterChanged)
    Q_PROPERTY(PrintFormat printFormat READ printFormat NOTIFY printFormatChanged)
    Q_PROPERTY(int copies READ copies NOTIFY copiesChanged)
    Q_PROPERTY(int maxCopies READ maxCopies CONSTANT)
    Q_PROPERTY(int extraCopyPrice READ extraCopyPrice CONSTANT)
    Q_PROPERTY(bool printerReady READ printerReady NOTIFY printerReadyChanged)
    Q_PROPERTY(QString finalImagePath READ finalImagePath NOTIFY finalImagePathChanged)
    Q_PROPERTY(QString shareUrl READ shareUrl NOTIFY finalImagePathChanged)

public:
    enum State {
        Idle,
        Connecting,
        LiveView,
        Review,
        FilterSelect,
        FormatSelect,
        Share
    };
    Q_ENUM(State)

    // Applied to the on-screen previews, and baked into the final print
    // image requestPrint() saves (finalImagePath).
    enum PhotoFilter {
        Original,
        Noir,
        Sepia,
        Vivid
    };
    Q_ENUM(PhotoFilter)

    enum PrintFormat {
        ClassicStrips, // two 2x6" strips, four shots each
        Postcard,      // one 4x6" single shot
        FourUp         // one 4x6" sheet, 2x2 grid
    };
    Q_ENUM(PrintFormat)

    explicit BoothController(CameraSource *source, QObject *parent = nullptr);

    State state() const { return m_state; }
    QString statusMessage() const { return m_statusMessage; }
    int countdownValue() const { return m_countdownValue; }
    // True between the camera delivering a photo and Review being ready
    // (decode + all filter previews run on a worker thread meanwhile).
    bool processing() const { return m_processing; }
    QString capturedImagePath() const { return m_capturedImagePath; }
    QString finalImagePath() const { return m_finalImagePath; }
    PhotoFilter filter() const { return m_filter; }
    PrintFormat printFormat() const { return m_printFormat; }
    int copies() const { return m_copies; }
    int maxCopies() const { return 10; }
    int extraCopyPrice() const { return 3; } // per copy beyond the first, in the booth's currency
    bool printerReady() const { return m_printerReady; }

    // Download link the Share screen's QR code encodes:
    // $PHOTOBOOTH_SHARE_BASE_URL/<final image file name>. Empty when that
    // variable isn't set — nothing uploads photos yet, so whatever serves
    // that base URL has to be set up separately.
    QString shareUrl() const;

    // No printer backend exists yet, so this stays false until one calls it.
    void setPrinterReady(bool ready);

    Q_INVOKABLE void startLiveView();
    Q_INVOKABLE void goIdle();
    Q_INVOKABLE void capture();

    // Shutter button entry point: counts 3, 2, 1 (countdownValue, once per
    // second) then calls capture(). Ignored if already counting down or
    // not in LiveView.
    Q_INVOKABLE void startCapture();

    // FilterSelect: tapping a thumbnail previews that filter
    // (photoFrameReady), Next keeps it and moves on to FormatSelect, Back
    // restores the filter active on entry and returns to Review.
    Q_INVOKABLE void openFilterSelect();
    Q_INVOKABLE void confirmFilterSelect();
    Q_INVOKABLE void cancelFilterSelect();
    Q_INVOKABLE void chooseFilter(PhotoFilter filter);

    // FormatSelect: format and copies reset to one classic-strips print on
    // entry; Back returns to FilterSelect. requestPrint() renders the final
    // print (filter + layout + `caption`, 300 DPI), saves it next to the
    // original, emits printRequested and moves on to Share.
    Q_INVOKABLE void openFormatSelect();
    Q_INVOKABLE void closeFormatSelect();
    Q_INVOKABLE void choosePrintFormat(PrintFormat format);
    Q_INVOKABLE void setCopies(int copies);
    Q_INVOKABLE void requestPrint(const QString &caption);

    // Share: printAnother() goes back to FormatSelect for another print of
    // the same photo, retake() starts a fresh live-view session, finish()
    // is goIdle(). Ending the session deletes the camera original, so only
    // final print images stay on disk — a guest who leaves before printing
    // leaves nothing behind. requestShare("email" | "sms") emits
    // shareRequested; nothing handles it yet.
    Q_INVOKABLE void printAnother();
    Q_INVOKABLE void retake();
    Q_INVOKABLE void finish();
    Q_INVOKABLE void requestShare(const QString &channel);

signals:
    void stateChanged();
    void statusMessageChanged();
    void countdownValueChanged();
    void processingChanged();
    void capturedImagePathChanged();
    void finalImagePathChanged();
    void filterChanged();
    void printFormatChanged();
    void copiesChanged();
    void printerReadyChanged();
    void imageCaptured(const QString &path);

    // The current photo with the current filter. Preview items connect to
    // this directly (see main.cpp) instead of going through a QML Image
    // source, so filter changes repaint without a file round-trip.
    void photoFrameReady(const QImage &image);

    // One-shot per capture: small per-filter previews for the FilterSelect
    // screen's thumbnail row.
    void thumbnailsReady(const QImage &original, const QImage &noir, const QImage &sepia, const QImage &vivid);

    // Hook for the (not yet written) print backend: the final print image
    // (filter and layout already applied) and how many copies to print.
    void printRequested(const QString &printImagePath, int copies);
    void shareRequested(const QString &channel, const QString &imagePath, const QString &shareUrl);

private:
    void setState(State state);
    void setStatusMessage(const QString &message);
    void setCountdownValue(int value);
    void cancelCountdown();
    void setFilter(PhotoFilter filter);
    void renderCurrentFilter();
    void setProcessing(bool processing);
    void discardOriginal();

    CameraSource *m_source;
    State m_state = Idle;
    QString m_statusMessage;
    QString m_capturedImagePath; // camera original, deleted when the session ends
    QString m_finalImagePath;    // last print image requestPrint() saved

    QTimer m_countdownTimer;
    int m_countdownValue = 0;

    // Everything the screens need from one capture, computed off the UI
    // thread so filter switching is just picking an already-filtered image.
    struct PreparedPhoto {
        QImage preview;     // downscaled original, also the print fallback
        QImage filtered[4]; // preview with each PhotoFilter applied
        QImage thumbs[4];   // square per-filter thumbnails
    };
    static PreparedPhoto preparePhoto(const QString &path);

    QImage m_capturedImage; // downscaled working copy (PreparedPhoto::preview)
    QImage m_filteredPreviews[4];
    QFutureWatcher<PreparedPhoto> m_prepareWatcher;
    // Bumped by goIdle(), so a result from an abandoned capture is ignored.
    int m_captureGeneration = 0;
    int m_preparingGeneration = 0; // m_captureGeneration when the running preparePhoto() started
    bool m_processing = false;
    PhotoFilter m_filter = Original;
    PhotoFilter m_filterBeforeSelect = Original; // restored by cancelFilterSelect()

    PrintFormat m_printFormat = ClassicStrips;
    int m_copies = 1;
    bool m_printerReady = false;
};
