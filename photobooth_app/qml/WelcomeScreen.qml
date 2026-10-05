import QtQuick
import Photobooth

Rectangle {
    id: root
    color: Theme.bg

    // Soft accent halo behind the title
    Rectangle {
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width
        height: 280
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1.0, 0.42, 0.29, 0.16) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spaceXl
        width: parent.width * 0.8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Strings.t("welcomeKicker")
            color: Theme.fgDim
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeCaption
            font.letterSpacing: 3
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: booth.state === BoothController.Connecting ? Strings.t("connecting") : Strings.t("welcomeTitle")
            color: Theme.fg
            font.family: Theme.displayFont
            font.pixelSize: Theme.sizeDisplayLg
        }

        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            visible: booth.statusMessage.length > 0 && booth.state === BoothController.Idle
            text: booth.statusMessage
            color: "#ff6b6b" // error state — deliberately distinct from the accent
            font.family: Theme.bodyFont
            font.pixelSize: Theme.sizeBody
        }
    }

    // Full-screen touch target (kiosk-friendly — anywhere works, not just the
    // button) with a visible pill CTA as the on-screen affordance.
    MouseArea {
        id: startArea
        anchors.fill: parent
        enabled: booth.state === BoothController.Idle
        onClicked: booth.startLiveView()

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Theme.spaceXl
            width: parent.width * 0.8
            height: Math.max(Theme.touchTargetMin, 64)
            radius: Theme.radiusMd
            color: startArea.pressed ? Qt.darker(Theme.accent, 1.15) : Theme.accent
            visible: booth.state === BoothController.Idle

            Text {
                anchors.centerIn: parent
                text: Strings.t("start")
                color: Theme.bg
                font.family: Theme.bodyFont
                font.pixelSize: Theme.sizeDisplayMd - 8
            }
        }
    }
}
