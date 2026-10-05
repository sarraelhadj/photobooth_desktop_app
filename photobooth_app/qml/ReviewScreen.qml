import QtQuick
import Photobooth

Rectangle {
    color: Theme.bgDeep

    // Reuses the same paint item live view uses — booth.photoFrameReady
    // (main.cpp) repaints it directly whenever the filter changes, so
    // switching filters never round-trips through the file on disk.
    LiveViewItem {
        id: reviewImageItem
        objectName: "reviewImageItem"
        anchors.fill: parent
        anchors.margins: Theme.spaceXl
    }

    // Bottom actions — same pair layout as the FilterSelect screen:
    // start over on the left, continue to filter selection on the right.
    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spaceXl
        width: 220
        height: Math.max(Theme.touchTargetMin, 64)
        radius: Theme.radiusPill
        color: retakeMouseArea.pressed ? Theme.bgAlt : Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.6)
        border.color: Theme.fg
        border.width: 2

        Text {
            anchors.centerIn: parent
            text: Strings.t("newPhoto")
            color: Theme.fg
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeDisplayMd - 8
        }

        MouseArea {
            id: retakeMouseArea
            anchors.fill: parent
            onClicked: booth.goIdle()
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spaceXl
        width: 220
        height: Math.max(Theme.touchTargetMin, 64)
        radius: Theme.radiusPill
        color: nextMouseArea.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent

        Text {
            anchors.centerIn: parent
            text: Strings.t("next")
            color: Theme.bg
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeDisplayMd - 8
        }

        MouseArea {
            id: nextMouseArea
            anchors.fill: parent
            onClicked: booth.openFilterSelect()
        }
    }
}
