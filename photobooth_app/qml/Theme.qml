pragma Singleton
import QtQuick

// Theme.qml — design tokens (colors, type, spacing) shared by every screen.
// Registered as the Photobooth.Theme singleton in main.cpp.
//
// Fonts: all guest-facing text uses Instrument Serif, a Google Font bundled
// in photobooth_app/fonts/ (main.cpp registers every .ttf/.otf there at
// startup). displayFont and bodyFont are kept as separate tokens so body
// text can move to a different family later without touching the screens.
// Instrument Serif only ships Regular + Italic — don't set a bold weight,
// Qt would fake one.

QtObject {
    // --- Colors ---------------------------------------------------------
    readonly property color bg:        "#17140F"
    readonly property color bgAlt:     "#211D16"
    readonly property color bgDeep:    "#0E0C09"   // camera preview placeholder base
    readonly property color fg:        "#F5F1E8"
    readonly property color fgDim:     "#A79C86"
    readonly property color fgFaint:   "#6B6153"
    readonly property color line:      Qt.rgba(0.961, 0.945, 0.910, 0.14)
    readonly property color lineSoft:  Qt.rgba(0.961, 0.945, 0.910, 0.10)

    // Single accent color. Writable (not readonly) so per-event branding can
    // override it at runtime.
    property color accent: "#FF6B4A"

    readonly property color success: "#6FCF7A"   // camera-connected dot

    // --- Typography -------------------------------------------------------
    // Sizes are set for Instrument Serif, which is narrow and small for its
    // pixel size — scale them back down if switching to a wider family.
    readonly property string displayFont: "Instrument Serif" // headings, countdown numeral
    readonly property string bodyFont: "Instrument Serif"    // everything else

    readonly property int sizeDisplayLg: 52
    readonly property int sizeDisplayMd: 34
    readonly property int sizeBody: 18
    readonly property int sizeCaption: 15
    readonly property int sizeMicro: 13

    // --- Spacing / radius ------------------------------------------------
    readonly property int radiusPill: 999
    readonly property int radiusLg: 20
    readonly property int radiusMd: 16
    readonly property int radiusSm: 10

    readonly property int spaceXs: 6
    readonly property int spaceSm: 12
    readonly property int spaceMd: 18
    readonly property int spaceLg: 24
    readonly property int spaceXl: 32

    readonly property int touchTargetMin: 44   // accessibility floor used throughout
}
