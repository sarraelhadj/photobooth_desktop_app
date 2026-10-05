# SARBOOTH — Canon EOS photobooth for Linux/ARM

A touch-screen photobooth kiosk written in Qt 6 / C++ that drives a
USB-tethered Canon EOS camera through Canon's **EDSDK**. It's developed on an
NVIDIA Jetson Orin Nano, but nothing in it is Jetson-specific: any Linux ARM64
machine that EDSDK supports should work.

The guest flow, in French or English:

1. **Welcome**: tap anywhere to start.
2. **Photo shoot**: live camera view with framing guides. Tapping the shutter
   starts a 3-2-1 countdown, then the camera takes the picture.
3. **Preview**: review the shot, retake it, or continue.
4. **Filter**: Original, Black & White, Sepia or Vivid, with live thumbnails.
5. **Format**: classic 2×6" strips, a 4×6" postcard or a 4×6" four-up sheet,
   plus the number of copies.
6. **Share**: the final print with a download QR code and options to print
   again, retake or finish.

## Architecture

```
photobooth_app (QML kiosk)        liveview_app (Qt Widgets diagnostic)
        │  Q_PROPERTY / Q_INVOKABLE / signals
BoothController (state machine, filters, print rendering)
        │  CameraSource interface
CanonEdsdkSource ── EDSDK ── USB ── Canon EOS camera
```

Everything above the camera layer is written against one abstract interface,
`CameraSource`, never against EDSDK directly. Another backend, such as Canon's
Wi-Fi CCAPI or gPhoto2, can be added as a second `CameraSource` implementation
without touching the UI.

| Path | What it is |
|---|---|
| [include/camerasource.h](include/camerasource.h) | The abstract `CameraSource` interface: connect, live view, capture and camera parameters. Every operation is asynchronous, and results come back as signals (`frameReady`, `imageCaptured`, `errorOccurred`, ...). |
| [src/canonedsdksource.cpp](src/canonedsdksource.cpp) | `CanonEdsdkSource`, the EDSDK implementation. It polls live-view JPEG frames on a timer (EDSDK has no push callback for them), polls `EdsGetEvent()` so camera events are dispatched at all on Linux, triggers captures and downloads them to `~/Pictures/photobooth/`. |
| [src/edserrorstring.cpp](src/edserrorstring.cpp) | Turns `EdsError` codes into readable names (EDSDK has no API for this). |
| [liveview_app/](liveview_app/) | A minimal Widgets window: connects, streams live view and shows the delivered FPS. Useful for checking a camera body before running the kiosk. |
| [photobooth_app/](photobooth_app/) | The kiosk. `BoothController` is the QML-facing state machine. `LiveViewItem` paints frames from C++ with no QML binding in the hot path. `QrCodeItem` draws QR codes. The screens are in [photobooth_app/qml/](photobooth_app/qml/), with translations in `Strings.qml` and design tokens in `Theme.qml`. |

### What happens to a photo

1. The camera sends the full-resolution JPEG to `~/Pictures/photobooth/`.
2. A worker thread decodes a preview-size copy and pre-renders all four
   filters, so switching filters is instant.
3. On **Print**, `BoothController::requestPrint()` renders the final print at
   300 DPI from the full-resolution original, with the filter, the layout and a
   date caption. It saves the result next to the original as
   `<name>_strips.jpg`, `<name>_postcard.jpg` or `<name>_fourup.jpg`.
4. When the session ends (Exit, Finish, Retake), the camera original is
   deleted. Only final print images stay on disk, and a guest who leaves
   before printing leaves nothing behind.

## Building

### Requirements

- Linux ARM64. Development uses a Jetson Orin Nano with Ubuntu 22.04,
  CMake 3.22 and Qt 6.2.
- Qt 6 with the Widgets, Quick, QuickControls2 and Concurrent modules.
- libqrencode: `sudo apt install libqrencode-dev`
- **Canon EDSDK for Linux.** It's free, but you have to register with the
  [Canon Developer Programme](https://developers.canon-usa.com/) to download
  it. **It is not included in this repository**: Canon distributes it under
  its own license agreement.

### Build

The build looks for EDSDK in a sibling directory by default:

```
some-parent-dir/
├── canon_interface/     (this repository)
└── EDSDKv132021L/       (Canon EDSDK, downloaded separately)
```

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
```

If EDSDK is somewhere else, pass `-DEDSDK_ROOT=/path/to/EDSDK/Linux/EDSDK`.

The build produces two programs:
- `build/photobooth_app/photobooth_app`: the kiosk.
- `build/liveview_app/liveview_app`: the live-view diagnostic.

`libEDSDK.so` is copied next to each executable, which finds it through an
`$ORIGIN` rpath.

Use a Release build for the kiosk. The image filters are plain pixel loops,
and without compiler optimization they run 3–5× slower.

### Configuration

| Environment variable | Effect |
|---|---|
| `PHOTOBOOTH_SHARE_BASE_URL` | Base URL for the Share screen's QR code, which encodes `$PHOTOBOOTH_SHARE_BASE_URL/<print file name>`. When it's unset, the screen says online sharing isn't set up. This app doesn't upload anything, so whatever serves that URL has to be set up separately. |

## Status and known limitations

This is a working prototype, not a finished product.

- **Camera I/O runs on the UI thread.** `CanonEdsdkSource` has no dedicated
  thread yet, so the full-resolution USB download after each shot blocks the
  UI while it runs. See the threading note at the end of
  [canonedsdksource.cpp](src/canonedsdksource.cpp).
- **One photo per session.** The strip and four-up layouts repeat the same
  photo until multi-shot capture is implemented.
- **No printing or sending yet.** `BoothController` emits `printRequested`
  with the final image and `shareRequested` for email/SMS, but nothing is
  connected to them. The printer status always reads "not connected".
- **Only ISO is mapped** in `setParameter()`/`parameter()`. Aperture, shutter
  speed, white balance and AF mode are declared but not mapped yet.
- **Only the first camera is used** when several are connected.
- **QML and fonts are loaded from the source tree** at runtime, through paths
  compiled into the binary. The app runs from a build of this checkout, and
  there's no install step yet.

## License

The code in this repository is released under the [MIT License](LICENSE).

Third-party components:

- **Canon EDSDK**: proprietary and not included. Use is governed by Canon's
  license agreement.
- **Qt 6**: LGPL-3.0, dynamically linked.
- **libqrencode**: LGPL-2.1, dynamically linked.
- **Instrument Serif** (`photobooth_app/fonts/`): SIL Open Font License 1.1,
  see [OFL.txt](photobooth_app/fonts/OFL.txt).
