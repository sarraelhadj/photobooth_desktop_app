import QtQuick
import Photobooth

// ShareScreen — final step, after Print: the printed result on a
// decorative panel (left), and on the right a QR code to download the
// photo, email/SMS share rows, and Print another / Retake / Finish.
//
// The QR code encodes booth.shareUrl, which is empty (placeholder shown)
// until PHOTOBOOTH_SHARE_BASE_URL is set — see BoothController::shareUrl().
// The email/SMS rows only emit booth.shareRequested for now.
Rectangle {
    id: root
    color: Theme.bg

    // --- Reusable pieces --------------------------------------------------

    component ShareRow: Rectangle {
        id: row
        property string iconName
        property color tint
        property string title
        property string hint
        property string channel

        height: 88
        radius: Theme.radiusLg
        color: rowArea.pressed ? Theme.bg : Theme.bgAlt
        border.color: Theme.lineSoft
        border.width: 1

        Rectangle {
            id: rowIcon
            anchors.left: parent.left
            anchors.leftMargin: Theme.spaceMd
            anchors.verticalCenter: parent.verticalCenter
            width: 56
            height: 56
            radius: Theme.radiusMd
            color: row.tint

            Icon {
                anchors.centerIn: parent
                width: 26
                height: 26
                name: row.iconName
                color: Theme.bg
            }
        }

        Column {
            anchors.left: rowIcon.right
            anchors.leftMargin: Theme.spaceMd
            anchors.right: chevron.left
            anchors.rightMargin: Theme.spaceSm
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: row.title
                color: Theme.fg
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeDisplayMd - 6
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: row.hint
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeBody - 1
            }
        }

        Icon {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: Theme.spaceMd
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            name: "chevron"
            color: Theme.fgDim
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            onClicked: booth.requestShare(row.channel)
        }
    }

    component ActionButton: Rectangle {
        id: button
        property string iconName
        property string text
        property bool primary: false
        signal clicked()

        height: primary ? 72 : 62
        radius: Theme.radiusPill
        color: primary ? (buttonArea.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent)
                       : (buttonArea.pressed ? Theme.bg : Theme.bgAlt)
        border.color: primary ? "transparent" : Theme.lineSoft
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: Theme.spaceSm
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                height: 22
                name: button.iconName
                color: button.primary ? Theme.bg : Theme.fg
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: button.text
                color: button.primary ? Theme.bg : Theme.fg
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeDisplayMd - 6
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            onClicked: button.clicked()
        }
    }

    // --- Left: result on a decorative panel ---------------------------------

    Item {
        id: resultPanel
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spaceXl
        width: 420

        // Rounded panel with two clipped colour blobs and a bit of confetti —
        // a Canvas so the blobs are cut by the rounded corners, which a
        // plain Rectangle's `clip` can't do.
        Canvas {
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var w = width, h = height, r = Theme.radiusLg * 2

                ctx.beginPath()
                ctx.moveTo(r, 0)
                ctx.arcTo(w, 0, w, h, r)
                ctx.arcTo(w, h, 0, h, r)
                ctx.arcTo(0, h, 0, 0, r)
                ctx.arcTo(0, 0, w, 0, r)
                ctx.closePath()
                ctx.fillStyle = Qt.tint(Theme.bgAlt, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22))
                ctx.fill()
                ctx.clip()

                ctx.fillStyle = Theme.accent
                ctx.beginPath()
                ctx.arc(w * 0.08, h * 0.06, w * 0.42, 0, 2 * Math.PI)
                ctx.fill()

                ctx.fillStyle = Theme.fgDim
                ctx.beginPath()
                ctx.arc(w * 1.0, h * 1.0, w * 0.3, 0, 2 * Math.PI)
                ctx.fill()

                // confetti
                ctx.fillStyle = Theme.fg
                ctx.beginPath()
                ctx.arc(w * 0.84, h * 0.12, 7, 0, 2 * Math.PI)
                ctx.fill()
                ctx.save()
                ctx.translate(w * 0.75, h * 0.14)
                ctx.rotate(-0.45)
                ctx.fillStyle = Theme.accent
                ctx.fillRect(-4, -14, 8, 28)
                ctx.restore()
            }
        }

        // Printer status pill
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: Theme.spaceLg
            anchors.horizontalCenter: parent.horizontalCenter
            width: printRow.implicitWidth + 28
            height: 40
            radius: Theme.radiusPill
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.82)

            Row {
                id: printRow
                anchors.centerIn: parent
                spacing: 8
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    name: "printer"
                    color: booth.printerReady ? Theme.success : Theme.fgFaint
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: booth.printerReady ? Strings.t("printingNow") : Strings.t("printerOffline")
                    color: Theme.fg
                    font.family: Theme.bodyFont
                    font.pixelSize: Theme.sizeBody
                }
            }
        }

        PrintPreview {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 6
            width: format === BoothController.ClassicStrips ? parent.width * 0.62 : parent.width - 2 * Theme.spaceXl
            maxHeight: parent.height - 190
            format: booth.printFormat
            stripCount: 1
            pad: 12
        }

        Text {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spaceLg
            anchors.horizontalCenter: parent.horizontalCenter
            visible: booth.printerReady
            text: Strings.t("printTray")
            color: Theme.fg
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeBody
        }
    }

    // --- Right: title, QR + share rows, actions -----------------------------

    Item {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: resultPanel.right
        anchors.right: parent.right
        anchors.margins: Theme.spaceXl
        anchors.leftMargin: Theme.spaceXl + Theme.spaceMd

        Column {
            id: heading
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: Theme.spaceSm

            Row {
                spacing: Theme.spaceMd
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Strings.t("sharedTitle")
                    color: Theme.fg
                    font.family: Theme.displayFont
                    font.pixelSize: Theme.sizeDisplayLg + 4
                }
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    height: 34
                    name: "sparkleFilled"
                    color: Theme.accent
                }
            }
            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: Strings.t("sharedHint")
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeBody + 3
            }
        }

        // QR card + share rows, centred in the space between heading and actions
        Item {
            anchors.top: heading.bottom
            anchors.bottom: actions.top
            anchors.left: parent.left
            anchors.right: parent.right

            Row {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: Theme.spaceMd

                Rectangle {
                    id: qrCard
                    width: 290
                    height: qrColumn.implicitHeight + 2 * Theme.spaceLg
                    radius: Theme.radiusLg
                    color: Theme.bgAlt
                    border.color: Theme.lineSoft
                    border.width: 1

                    Column {
                        id: qrColumn
                        anchors.centerIn: parent
                        spacing: Theme.spaceSm

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 210
                            height: 210
                            radius: Theme.radiusMd
                            color: "#FBF8F2"

                            QrCodeItem {
                                id: qrCode
                                anchors.fill: parent
                                anchors.margins: 6
                                text: booth.shareUrl
                                darkColor: Theme.bg
                                lightColor: "#FBF8F2"
                            }

                            Text {
                                anchors.fill: parent
                                anchors.margins: Theme.spaceLg
                                visible: !qrCode.valid
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                wrapMode: Text.WordWrap
                                text: Strings.t("shareNotConfigured")
                                color: Theme.fgFaint
                                font.family: Theme.bodyFont
                                font.pixelSize: Theme.sizeBody
                            }
                        }

                        Item { width: 1; height: 2 }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Strings.t("scanToDownload")
                            color: Theme.fg
                            font.family: Theme.bodyFont
                            font.pixelSize: Theme.sizeDisplayMd - 6
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Strings.t("scanHint")
                            color: Theme.fgDim
                            font.family: Theme.bodyFont
                            font.pixelSize: Theme.sizeBody - 1
                        }
                    }
                }

                Column {
                    anchors.verticalCenter: qrCard.verticalCenter
                    width: parent.width - qrCard.width - parent.spacing
                    spacing: Theme.spaceSm

                    ShareRow {
                        width: parent.width
                        iconName: "mail"
                        tint: Theme.accent
                        title: Strings.t("shareEmail")
                        hint: Strings.t("shareEmailHint")
                        channel: "email"
                    }
                    ShareRow {
                        width: parent.width
                        iconName: "chat"
                        tint: Theme.fgDim
                        title: Strings.t("shareSms")
                        hint: Strings.t("shareSmsHint")
                        channel: "sms"
                    }
                }
            }
        }

        Column {
            id: actions
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: Theme.spaceSm

            Row {
                width: parent.width
                spacing: Theme.spaceSm

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    iconName: "printer"
                    text: Strings.t("printAnother")
                    onClicked: booth.printAnother()
                }
                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    iconName: "camera"
                    text: Strings.t("retake")
                    onClicked: booth.retake()
                }
            }

            ActionButton {
                width: parent.width
                primary: true
                iconName: "sparkle"
                text: Strings.t("finish")
                onClicked: booth.finish()
            }
        }
    }
}
