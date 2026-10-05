import QtQuick
import Photobooth

// FormatSelectScreen — "Choose your print": three print-layout cards on the
// left, a print-details panel (format summary, copies stepper, Print / Back)
// on the right.
//
// The layout previews are PrintPreview items (see PrintPreview.qml for how
// their photo cells get the current filtered photo).
Rectangle {
    id: root
    color: Theme.bg

    // --- Reusable pieces --------------------------------------------------

    component Badge: Rectangle {
        property string text
        property bool highlighted: false
        width: badgeLabel.implicitWidth + 20
        height: 28
        radius: Theme.radiusPill
        color: highlighted ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)

        Text {
            id: badgeLabel
            anchors.centerIn: parent
            text: parent.text
            color: parent.highlighted ? Theme.bg : Theme.fgDim
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeMicro
            font.letterSpacing: 1
        }
    }

    // One selectable layout: name, size, badge, and a preview area its
    // children (the PrintPreview) go into.
    component FormatCard: Rectangle {
        id: card
        property int format
        property string keyPrefix
        property string badgeText
        default property alias preview: previewArea.data
        readonly property bool selected: booth.printFormat === format

        radius: Theme.radiusLg
        color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06) : Theme.bgAlt
        border.width: selected ? 3 : 1
        border.color: selected ? Theme.accent : Theme.lineSoft
        Behavior on border.color { ColorAnimation { duration: 150 } }

        Column {
            id: cardHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.spaceMd
            spacing: 4

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: Strings.t(card.keyPrefix)
                color: Theme.fg
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeDisplayMd - 6
            }
            Text {
                text: Strings.t(card.keyPrefix + "Size")
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeBody - 1
            }
        }

        Rectangle {
            id: previewArea
            anchors.top: cardHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spaceMd
            anchors.topMargin: Theme.spaceMd
            radius: Theme.radiusMd
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.035)
        }

        // In the preview's corner rather than beside the title, so long
        // (e.g. French) names and badges never squeeze each other.
        Badge {
            anchors.top: previewArea.top
            anchors.right: previewArea.right
            anchors.margins: Theme.spaceSm
            text: card.selected ? Strings.t("badgeSelected") : card.badgeText
            highlighted: card.selected
            visible: text.length > 0
        }

        MouseArea {
            anchors.fill: parent
            onClicked: booth.choosePrintFormat(card.format)
        }
    }

    // --- Left: title + format cards ---------------------------------------

    Item {
        id: formatsArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.right: detailsPanel.left
        anchors.margins: Theme.spaceXl
        anchors.rightMargin: Theme.spaceLg

        Column {
            id: heading
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: printerPill.left
            anchors.rightMargin: Theme.spaceMd
            spacing: Theme.spaceXs

            Text {
                text: Strings.t("chooseFormatTitle")
                color: Theme.fg
                font.family: Theme.displayFont
                font.pixelSize: Theme.sizeDisplayLg
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: Strings.t("chooseFormatHint")
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeBody + 2
            }
        }

        // Printer status — booth.printerReady stays false until a print
        // backend reports in (see BoothController::setPrinterReady()).
        Rectangle {
            id: printerPill
            anchors.right: parent.right
            anchors.bottom: heading.bottom
            width: printerRow.implicitWidth + 24
            height: 36
            radius: Theme.radiusPill
            color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)

            Row {
                id: printerRow
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
                    text: booth.printerReady ? Strings.t("printerReady") : Strings.t("printerOffline")
                    color: booth.printerReady ? Theme.success : Theme.fgDim
                    font.family: Theme.bodyFont
                    font.pixelSize: Theme.sizeCaption + 1
                }
            }
        }

        Row {
            id: cards
            anchors.top: heading.bottom
            anchors.topMargin: Theme.spaceLg
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: Theme.spaceMd

            readonly property real cardWidth: (width - 2 * spacing) / 3

            FormatCard {
                width: cards.cardWidth
                height: cards.height
                format: BoothController.ClassicStrips
                keyPrefix: "formatStrips"

                PrintPreview {
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.spaceLg
                    maxHeight: parent.height - 2 * Theme.spaceXl
                    format: BoothController.ClassicStrips
                }
            }

            FormatCard {
                width: cards.cardWidth
                height: cards.height
                format: BoothController.Postcard
                keyPrefix: "formatPostcard"
                badgeText: Strings.t("badgePopular")

                PrintPreview {
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.spaceMd
                    format: BoothController.Postcard
                }
            }

            FormatCard {
                width: cards.cardWidth
                height: cards.height
                format: BoothController.FourUp
                keyPrefix: "formatFourUp"
                badgeText: Strings.t("badgeAllShots")

                PrintPreview {
                    anchors.centerIn: parent
                    width: parent.width - 2 * Theme.spaceMd
                    format: BoothController.FourUp
                }
            }
        }
    }

    // --- Right: print details -----------------------------------------------

    Rectangle {
        id: detailsPanel
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spaceXl
        width: 330
        radius: Theme.radiusLg
        color: Theme.bgAlt
        border.color: Theme.lineSoft
        border.width: 1

        Column {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceMd

            Text {
                text: Strings.t("printDetails")
                color: Theme.fg
                font.family: Theme.displayFont
                font.pixelSize: Theme.sizeDisplayMd + 2
            }

            Item {
                width: parent.width
                height: formatValue.implicitHeight
                Text {
                    text: Strings.t("format")
                    color: Theme.fgDim
                    font.family: Theme.bodyFont
                    font.pixelSize: Theme.sizeBody + 2
                }
                Text {
                    id: formatValue
                    anchors.right: parent.right
                    text: Strings.formatSummary(booth.printFormat)
                    color: Theme.fg
                    font.family: Theme.bodyFont
                    font.pixelSize: Theme.sizeBody + 2
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.line
            }

            Text {
                text: Strings.t("copies")
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeBody + 2
            }

            // Copies stepper: −  n  +
            Rectangle {
                width: parent.width
                height: 64
                radius: Theme.radiusPill
                color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.05)

                Rectangle {
                    enabled: booth.copies > 1
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 48
                    height: 48
                    radius: 24
                    color: minusArea.pressed ? Theme.bg : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.06)
                    opacity: enabled ? 1 : 0.45

                    Rectangle {
                        anchors.centerIn: parent
                        width: 16
                        height: 2
                        radius: 1
                        color: Theme.fgDim
                    }
                    MouseArea {
                        id: minusArea
                        anchors.fill: parent
                        onClicked: booth.setCopies(booth.copies - 1)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: booth.copies
                    color: Theme.fg
                    font.family: Theme.bodyFont
                    font.pixelSize: Theme.sizeDisplayMd + 4
                }

                Rectangle {
                    enabled: booth.copies < booth.maxCopies
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 48
                    height: 48
                    radius: 24
                    color: plusArea.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent
                    opacity: enabled ? 1 : 0.45

                    Repeater {
                        model: [0, 90]
                        Rectangle {
                            anchors.centerIn: parent
                            width: 16
                            height: 2
                            radius: 1
                            color: Theme.bg
                            rotation: modelData
                        }
                    }
                    MouseArea {
                        id: plusArea
                        anchors.fill: parent
                        onClicked: booth.setCopies(booth.copies + 1)
                    }
                }
            }

            Text {
                width: parent.width
                wrapMode: Text.WordWrap
                text: Strings.t("copiesNote").arg(Strings.t("price").arg(booth.extraCopyPrice))
                color: Theme.accent
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeBody - 1
            }
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Theme.spaceLg
            spacing: Theme.spaceSm

            Rectangle {
                width: parent.width
                height: 68
                radius: Theme.radiusPill
                color: printArea.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spaceSm
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "printer"
                        color: Theme.bg
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.t("printIt")
                        color: Theme.bg
                        font.family: Theme.bodyFont
                        font.pixelSize: Theme.sizeDisplayMd - 6
                    }
                }
                MouseArea {
                    id: printArea
                    anchors.fill: parent
                    onClicked: booth.requestPrint(Strings.printCaption())
                }
            }

            Rectangle {
                width: parent.width
                height: 56
                radius: Theme.radiusPill
                color: backArea.pressed ? Theme.bg : "transparent"
                border.color: Theme.line
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: Theme.spaceSm
                    Icon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: "back"
                        color: Theme.fgDim
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Strings.t("back")
                        color: Theme.fg
                        font.family: Theme.bodyFont
                        font.pixelSize: Theme.sizeDisplayMd - 6
                    }
                }
                MouseArea {
                    id: backArea
                    anchors.fill: parent
                    onClicked: booth.closeFormatSelect()
                }
            }
        }
    }
}
