import QtQuick
import Photobooth

// LiveViewScreen — step 2: the camera feed in a rounded frame with framing
// corners, LIVE badge and a "look here" hint (left), and a panel with the
// title, countdown explanation and shutter button (right).
Rectangle {
    id: root
    color: Theme.bg

    // One framing corner (an "L"), drawn for the top-left position; the
    // other three are the same shape rotated in place.
    component FrameCorner: Item {
        width: 52
        height: 52
        Rectangle {
            width: parent.width
            height: 4
            radius: 2
            color: Theme.fg
        }
        Rectangle {
            width: 4
            height: parent.height
            radius: 2
            color: Theme.fg
        }
    }

    // --- Left: camera feed --------------------------------------------------

    Item {
        id: viewArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.right: sidePanel.left
        anchors.margins: Theme.spaceXl

        // Sized to the camera's 3:2 live-view aspect, so the letterboxed
        // feed fills the frame without cropping what the photo will contain.
        Item {
            id: frame
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height * 1.5)
            height: width / 1.5

            LiveViewItem {
                id: liveViewItem
                objectName: "liveViewItem"
                anchors.fill: parent
                radius: Theme.radiusLg + 8
            }

            // Framing corners
            Item {
                anchors.fill: parent
                anchors.leftMargin: parent.width * 0.1
                anchors.rightMargin: parent.width * 0.1
                anchors.topMargin: parent.height * 0.09
                anchors.bottomMargin: parent.height * 0.09

                FrameCorner { anchors.top: parent.top; anchors.left: parent.left }
                FrameCorner { anchors.top: parent.top; anchors.right: parent.right; rotation: 90 }
                FrameCorner { anchors.bottom: parent.bottom; anchors.right: parent.right; rotation: 180 }
                FrameCorner { anchors.bottom: parent.bottom; anchors.left: parent.left; rotation: 270 }
            }

            // LIVE badge
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: Theme.spaceMd
                radius: Theme.radiusPill
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.75)
                height: liveRow.implicitHeight + 14
                width: liveRow.implicitWidth + 28

                Row {
                    id: liveRow
                    anchors.centerIn: parent
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        color: Theme.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.t("live")
                        color: Theme.fg
                        font.family: Theme.bodyFont
                        font.pixelSize: Theme.sizeCaption
                        font.letterSpacing: 1
                    }
                }
            }

            // "Everyone in?" hint — hidden while counting down or processing
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.spaceLg
                anchors.horizontalCenter: parent.horizontalCenter
                visible: booth.countdownValue === 0 && !booth.processing
                radius: Theme.radiusPill
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.75)
                height: hintRow.implicitHeight + 16
                width: hintRow.implicitWidth + 32

                Row {
                    id: hintRow
                    anchors.centerIn: parent
                    spacing: Theme.spaceSm
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "people"
                        color: Theme.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.t("lookHere")
                        color: Theme.fg
                        font.family: Theme.bodyFont
                        font.pixelSize: Theme.sizeBody + 2
                    }
                }
            }

            // Shown while the captured photo is decoded and its filter
            // previews are prepared (BoothController::processing).
            Rectangle {
                anchors.centerIn: parent
                visible: booth.processing
                radius: Theme.radiusPill
                color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.85)
                height: processingRow.implicitHeight + 24
                width: processingRow.implicitWidth + 40

                Row {
                    id: processingRow
                    anchors.centerIn: parent
                    spacing: Theme.spaceSm

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 10
                        radius: 5
                        color: Theme.accent
                        SequentialAnimation on opacity {
                            running: booth.processing
                            loops: Animation.Infinite
                            NumberAnimation { from: 1; to: 0.25; duration: 450 }
                            NumberAnimation { from: 0.25; to: 1; duration: 450 }
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.t("processing")
                        color: Theme.fg
                        font.family: Theme.bodyFont
                        font.pixelSize: Theme.sizeBody + 4
                    }
                }
            }

            // Countdown overlay, centred on the camera frame — 3/2/1, one per
            // second, then the shutter fires (see BoothController::startCapture()).
            // A title above, the numeral in a ringed accent disc, a hint line
            // below; each new number pops in with a short scale animation.
            Column {
                anchors.centerIn: parent
                spacing: Theme.spaceLg
                visible: booth.countdownValue > 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Strings.t("countdownTitle")
                    color: Theme.fg
                    font.family: Theme.bodyFont
                    font.pixelSize: Theme.sizeDisplayMd
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.35)
                }

                Rectangle {
                    id: countdownDisc
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 300
                    height: 300
                    radius: width / 2
                    color: Theme.accent
                    border.color: Theme.fg
                    border.width: 10

                    Text {
                        anchors.centerIn: parent
                        text: booth.countdownValue
                        color: Theme.bg
                        font.family: Theme.displayFont
                        font.pixelSize: 190
                    }

                    SequentialAnimation {
                        id: popAnimation
                        NumberAnimation { target: countdownDisc; property: "scale"; from: 0.82; to: 1.04; duration: 180; easing.type: Easing.OutCubic }
                        NumberAnimation { target: countdownDisc; property: "scale"; to: 1.0; duration: 120; easing.type: Easing.InOutQuad }
                    }

                    Connections {
                        target: booth
                        function onCountdownValueChanged() {
                            if (booth.countdownValue > 0)
                                popAnimation.restart()
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Strings.t("countdownHint")
                    color: Theme.fg
                    font.family: Theme.bodyFont
                    font.pixelSize: Theme.sizeBody + 5
                    style: Text.Raised
                    styleColor: Qt.rgba(0, 0, 0, 0.35)
                }
            }
        }
    }

    // --- Right: title, explanation, shutter ---------------------------------

    Item {
        id: sidePanel
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spaceXl
        width: 370

        Column {
            id: intro
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Theme.spaceMd

            // Shots per session — one until multi-shot capture exists
            Rectangle {
                width: countRow.implicitWidth + 28
                height: 36
                radius: Theme.radiusPill
                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.14)

                Row {
                    id: countRow
                    anchors.centerIn: parent
                    spacing: 8
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        height: 18
                        name: "photos"
                        color: Theme.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.t("photoCount")
                        color: Theme.accent
                        font.family: Theme.bodyFont
                        font.pixelSize: Theme.sizeCaption
                        font.letterSpacing: 1
                    }
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: Strings.t("liveTitle")
                color: Theme.fg
                font.family: Theme.displayFont
                font.pixelSize: Theme.sizeDisplayLg - 6
                lineHeight: 0.95
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: Strings.t("liveHint")
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeBody + 3
                lineHeight: 1.15
            }
        }

        // Shutter: starts the 3-2-1 countdown rather than shooting
        // immediately; BoothController fires capture() once it reaches zero.
        Item {
            anchors.top: intro.bottom
            anchors.bottom: statusText.top
            anchors.left: parent.left
            anchors.right: parent.right

            Column {
                anchors.centerIn: parent
                spacing: Theme.spaceMd

                Rectangle {
                    id: shutter
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 144
                    height: 144
                    radius: 72
                    color: Theme.fg
                    enabled: booth.state === BoothController.LiveView && booth.countdownValue === 0 && !booth.processing
                    opacity: enabled ? 1 : 0.4
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 128
                        height: 128
                        radius: 64
                        color: Theme.bg

                        Rectangle {
                            anchors.centerIn: parent
                            width: 108
                            height: 108
                            radius: 54
                            color: shutterArea.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                            Icon {
                                anchors.centerIn: parent
                                width: 36
                                height: 36
                                name: "camera"
                                color: Theme.fg
                            }
                        }
                    }

                    MouseArea {
                        id: shutterArea
                        anchors.fill: parent
                        onClicked: booth.startCapture()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Strings.t("tapWhenReady")
                    color: Theme.fg
                    font.family: Theme.bodyFont
                    font.pixelSize: Theme.sizeDisplayMd - 6
                }
            }
        }

        // Camera / error status (e.g. a failed capture) for the operator
        Text {
            id: statusText
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: booth.statusMessage
            color: Theme.fgFaint
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeCaption
        }
    }
}
