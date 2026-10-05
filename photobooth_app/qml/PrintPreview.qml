import QtQuick
import Photobooth

// PrintPreview.qml — on-screen paper preview of one print layout (BoothController::
// PrintFormat), used by the FormatSelect cards and the Share screen.
//
// Set `width` (and optionally `maxHeight`); the preview sizes itself to fit
// both and reports its height via implicitHeight.
//
// Every photo cell is a LiveViewItem tagged "printPhoto", which main.cpp
// connects to booth.photoFrameReady at startup. That's why all three
// layouts are always instantiated and only toggled with `visible` — a
// Loader would create cells after main.cpp has already looked for them.
Item {
    id: preview

    property int format: BoothController.ClassicStrips
    property int stripCount: 2       // strips side by side for ClassicStrips
    property real maxHeight: 100000
    property real pad: 8             // paper border around the photos

    readonly property color paper: "#FBF8F2"
    readonly property color paperInk: "#2A251D"

    readonly property string caption: Strings.printCaption()

    implicitHeight: format === BoothController.Postcard ? postcard.height
                  : format === BoothController.FourUp ? fourUp.height
                  : strips.height

    component PrintPhoto: LiveViewItem {
        objectName: "printPhoto"
        cropToFill: true
    }

    // --- Classic strips: N strips of four stacked shots -----------------
    Row {
        id: strips
        anchors.horizontalCenter: parent.horizontalCenter
        visible: preview.format === BoothController.ClassicStrips
        spacing: 12

        // Strip height ≈ 3.05 × cell width + borders (four 0.68-ratio shots,
        // gaps and the caption band), so the cell fits whichever of width
        // and maxHeight is tighter.
        readonly property real cell: Math.max(10, Math.min(
            (preview.width - (preview.stripCount - 1) * spacing) / preview.stripCount - 2 * preview.pad,
            (preview.maxHeight - 2 * preview.pad - 14) / 3.05))

        Repeater {
            model: preview.stripCount
            Rectangle {
                width: strips.cell + 2 * preview.pad
                height: stripColumn.implicitHeight + 2 * preview.pad
                radius: 6
                color: preview.paper

                Column {
                    id: stripColumn
                    anchors.top: parent.top
                    anchors.topMargin: preview.pad
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: strips.cell * 0.05 + 2

                    Repeater {
                        model: 4
                        PrintPhoto {
                            width: strips.cell
                            height: strips.cell * 0.68
                        }
                    }

                    Text {
                        width: strips.cell
                        height: strips.cell * 0.14 + 10
                        horizontalAlignment: preview.stripCount === 1 ? Text.AlignLeft : Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        // A single wide strip has room for the dated caption.
                        text: preview.stripCount === 1 ? preview.caption : "SARBOOTH"
                        color: preview.paperInk
                        font.family: Theme.bodyFont
                        font.pixelSize: Math.max(9, strips.cell * 0.055)
                        font.letterSpacing: 0.5
                    }
                }
            }
        }
    }

    // --- Postcard: one wide shot + caption ------------------------------
    Rectangle {
        id: postcard
        anchors.horizontalCenter: parent.horizontalCenter
        visible: preview.format === BoothController.Postcard
        width: Math.min(preview.width, (preview.maxHeight - 38) / 0.56 + 2 * preview.pad)
        height: postcardPhoto.height + preview.pad + 38
        radius: 6
        color: preview.paper

        PrintPhoto {
            id: postcardPhoto
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: preview.pad
            height: width * 0.56
        }
        Text {
            anchors.top: postcardPhoto.bottom
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            verticalAlignment: Text.AlignVCenter
            text: preview.caption
            color: preview.paperInk
            font.family: Theme.bodyFont
            font.pixelSize: Math.max(10, postcard.width * 0.04)
            font.letterSpacing: 0.5
        }
    }

    // --- Four-up: 2x2 grid on one sheet ---------------------------------
    Rectangle {
        id: fourUp
        anchors.horizontalCenter: parent.horizontalCenter
        visible: preview.format === BoothController.FourUp
        width: Math.min(preview.width, (preview.maxHeight - 2 * preview.pad) / 0.68 + 2 * preview.pad)
        height: fourUpGrid.height + 2 * preview.pad
        radius: 6
        color: preview.paper

        Grid {
            id: fourUpGrid
            anchors.centerIn: parent
            columns: 2
            spacing: 5
            readonly property real cell: (fourUp.width - 2 * preview.pad - spacing) / 2

            Repeater {
                model: 4
                PrintPhoto {
                    width: fourUpGrid.cell
                    height: fourUpGrid.cell * 0.68
                }
            }
        }
    }
}
