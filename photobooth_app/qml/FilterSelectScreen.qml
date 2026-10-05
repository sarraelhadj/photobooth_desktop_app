import QtQuick
import Photobooth

Rectangle {
    color: Theme.bgDeep

    Column {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: Theme.spaceXl
        spacing: Theme.spaceXs

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Strings.t("chooseFilterTitle")
            color: Theme.fg
            font.family: Theme.displayFont
            font.pixelSize: Theme.sizeDisplayMd
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Strings.t("chooseFilterHint")
            color: Theme.fgDim
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeBody
        }
    }

    // Live preview of the currently selected filter — repainted by
    // booth.photoFrameReady whenever chooseFilter() runs (see main.cpp).
    LiveViewItem {
        id: filterPreviewItem
        objectName: "filterPreviewItem"
        anchors.top: parent.top
        anchors.topMargin: 130
        anchors.bottom: thumbnailRow.top
        anchors.bottomMargin: Theme.spaceLg
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.4
    }

    Row {
        id: thumbnailRow
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 150
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.spaceLg

        Column {
            spacing: Theme.spaceXs
            Rectangle {
                width: 110
                height: 110
                radius: Theme.radiusMd
                color: "transparent"
                border.width: booth.filter === BoothController.Original ? 3 : 1
                border.color: booth.filter === BoothController.Original ? Theme.accent : Theme.line

                LiveViewItem {
                    objectName: "thumbOriginal"
                    anchors.fill: parent
                    anchors.margins: 3
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: booth.chooseFilter(BoothController.Original)
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Strings.filterName(BoothController.Original)
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeCaption
            }
        }

        Column {
            spacing: Theme.spaceXs
            Rectangle {
                width: 110
                height: 110
                radius: Theme.radiusMd
                color: "transparent"
                border.width: booth.filter === BoothController.Noir ? 3 : 1
                border.color: booth.filter === BoothController.Noir ? Theme.accent : Theme.line

                LiveViewItem {
                    objectName: "thumbNoir"
                    anchors.fill: parent
                    anchors.margins: 3
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: booth.chooseFilter(BoothController.Noir)
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Strings.filterName(BoothController.Noir)
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeCaption
            }
        }

        Column {
            spacing: Theme.spaceXs
            Rectangle {
                width: 110
                height: 110
                radius: Theme.radiusMd
                color: "transparent"
                border.width: booth.filter === BoothController.Sepia ? 3 : 1
                border.color: booth.filter === BoothController.Sepia ? Theme.accent : Theme.line

                LiveViewItem {
                    objectName: "thumbSepia"
                    anchors.fill: parent
                    anchors.margins: 3
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: booth.chooseFilter(BoothController.Sepia)
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Strings.filterName(BoothController.Sepia)
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeCaption
            }
        }

        Column {
            spacing: Theme.spaceXs
            Rectangle {
                width: 110
                height: 110
                radius: Theme.radiusMd
                color: "transparent"
                border.width: booth.filter === BoothController.Vivid ? 3 : 1
                border.color: booth.filter === BoothController.Vivid ? Theme.accent : Theme.line

                LiveViewItem {
                    objectName: "thumbVivid"
                    anchors.fill: parent
                    anchors.margins: 3
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: booth.chooseFilter(BoothController.Vivid)
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Strings.filterName(BoothController.Vivid)
                color: Theme.fgDim
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeCaption
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spaceXl
        width: 180
        height: Math.max(Theme.touchTargetMin, 64)
        radius: Theme.radiusPill
        color: "transparent"
        border.color: Theme.fg
        border.width: 2

        Text {
            anchors.centerIn: parent
            text: Strings.t("back")
            color: Theme.fg
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeDisplayMd - 8
        }

        MouseArea {
            anchors.fill: parent
            onClicked: booth.cancelFilterSelect()
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Theme.spaceXl
        width: 180
        height: Math.max(Theme.touchTargetMin, 64)
        radius: Theme.radiusPill
        color: suivantMouseArea.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent

        Text {
            anchors.centerIn: parent
            text: Strings.t("next")
            color: Theme.bg
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeDisplayMd - 8
        }

        MouseArea {
            id: suivantMouseArea
            anchors.fill: parent
            onClicked: booth.confirmFilterSelect()
        }
    }
}
