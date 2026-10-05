import QtQuick
import Photobooth

// TopBar — shown above every screen (see Main.qml): logo + brand on the
// left, "STEP n OF N" with a dot progress indicator and the step name in
// the middle, and on the right a FR/EN language toggle plus an Exit button
// that returns to Welcome.
Rectangle {
    id: root

    // The guest flow in order, as Strings keys so step names follow the
    // selected language. stepIndex maps BoothController states onto it.
    readonly property var steps: ["stepWelcome", "stepLiveView", "stepReview", "stepFilter", "stepFormat", "stepShare"]

    readonly property int stepIndex: {
        switch (booth.state) {
        case BoothController.Idle:
        case BoothController.Connecting:   return 0
        case BoothController.LiveView:     return 1
        case BoothController.Review:       return 2
        case BoothController.FilterSelect: return 3
        case BoothController.FormatSelect: return 4
        case BoothController.Share:        return 5
        }
        return 0
    }

    height: 86
    color: Theme.bg

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.lineSoft
    }

    // --- Left: logo + brand ---------------------------------------------
    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.spaceXl
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spaceSm

        Rectangle {
            width: 44
            height: 44
            radius: Theme.radiusSm + 2
            color: Theme.accent

            // Sparkle glyph: one large four-point star plus two small ones,
            // drawn rather than taken from a font so it renders the same on
            // the kiosk regardless of installed glyphs.
            Canvas {
                anchors.fill: parent
                anchors.margins: 9
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = Theme.fg
                    ctx.lineWidth = 1.6
                    ctx.lineJoin = "round"

                    function star(cx, cy, r) {
                        var k = r * 0.28
                        ctx.beginPath()
                        ctx.moveTo(cx, cy - r)
                        ctx.quadraticCurveTo(cx + k, cy - k, cx + r, cy)
                        ctx.quadraticCurveTo(cx + k, cy + k, cx, cy + r)
                        ctx.quadraticCurveTo(cx - k, cy + k, cx - r, cy)
                        ctx.quadraticCurveTo(cx - k, cy - k, cx, cy - r)
                        ctx.closePath()
                        ctx.stroke()
                    }

                    star(width * 0.42, height * 0.55, width * 0.36)
                    star(width * 0.82, height * 0.16, width * 0.14)
                    star(width * 0.16, height * 0.88, width * 0.1)
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "SARBOOTH"
            color: Theme.fg
            font.family: Theme.bodyFont
            font.pixelSize: 22
            font.letterSpacing: 1
        }
    }

    // --- Center: step counter + progress dots + step name ---------------
    Row {
        anchors.centerIn: parent
        spacing: Theme.spaceMd

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Strings.t("stepCounter").arg(root.stepIndex + 1).arg(root.steps.length)
            color: Theme.fgDim
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeCaption
            font.letterSpacing: 1
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Repeater {
                model: root.steps.length
                Rectangle {
                    readonly property bool current: index === root.stepIndex
                    anchors.verticalCenter: parent.verticalCenter
                    width: current ? 28 : 8
                    height: 8
                    radius: 4
                    // Current and already-passed steps are filled with the accent
                    color: index <= root.stepIndex ? Theme.accent : Theme.fgFaint
                    Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Strings.t(root.steps[root.stepIndex])
            color: Theme.fg
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeBody + 3
        }
    }

    // --- Right: language toggle + Exit -----------------------------------
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceXl
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spaceSm

        // Segmented FR | EN pill — tapping a language applies it immediately
        // (every label is bound through Strings.t()).
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: langRow.implicitWidth + 8
            height: Math.max(Theme.touchTargetMin, 48)
            radius: Theme.radiusMd
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04)
            border.color: Theme.line
            border.width: 1

            Row {
                id: langRow
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: Strings.languages
                    Rectangle {
                        readonly property bool selected: modelData === Strings.language
                        width: 52
                        height: 40
                        radius: Theme.radiusMd - 4
                        color: selected ? Theme.accent : (langMouseArea.pressed ? Theme.bgAlt : "transparent")
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.toUpperCase()
                            color: parent.selected ? Theme.bg : Theme.fgDim
                            font.family: Theme.bodyFont
                            font.pixelSize: Theme.sizeBody
                            font.letterSpacing: 1
                        }

                        MouseArea {
                            id: langMouseArea
                            anchors.fill: parent
                            onClicked: Strings.language = modelData
                        }
                    }
                }
            }
        }

        // Hidden on Welcome since there's nothing to exit from there.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: exitRow.implicitWidth + Theme.spaceLg * 2
            height: Math.max(Theme.touchTargetMin, 48)
            radius: Theme.radiusMd
            color: exitMouseArea.pressed ? Theme.bgAlt : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.04)
            border.color: Theme.line
            border.width: 1
            visible: booth.state !== BoothController.Idle

            Row {
                id: exitRow
                anchors.centerIn: parent
                spacing: Theme.spaceSm - 2

                // "×" drawn as two crossed bars so it doesn't depend on the font
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    Repeater {
                        model: [45, -45]
                        Rectangle {
                            anchors.centerIn: parent
                            width: 16
                            height: 1.5
                            radius: 1
                            color: Theme.fgDim
                            rotation: modelData
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Strings.t("exit")
                    color: Theme.fgDim
                    font.family: Theme.bodyFont
                    font.pixelSize: Theme.sizeBody + 3
                }
            }

            MouseArea {
                id: exitMouseArea
                anchors.fill: parent
                onClicked: booth.goIdle()
            }
        }
    }
}
