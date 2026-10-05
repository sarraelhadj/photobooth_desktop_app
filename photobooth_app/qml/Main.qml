import QtQuick
import QtQuick.Window
import Photobooth

Window {
    id: root
    visible: true
    width: 1280
    height: 800
    color: Theme.bg
    title: "Photobooth"

    TopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 1
    }

    // Every screen fills the area below the top bar.
    Item {
        id: content
        anchors.top: topBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        WelcomeScreen {
            anchors.fill: parent
            visible: booth.state === BoothController.Idle || booth.state === BoothController.Connecting
        }

        LiveViewScreen {
            anchors.fill: parent
            visible: booth.state === BoothController.LiveView
        }

        ReviewScreen {
            anchors.fill: parent
            visible: booth.state === BoothController.Review
        }

        FilterSelectScreen {
            anchors.fill: parent
            visible: booth.state === BoothController.FilterSelect
        }

        FormatSelectScreen {
            anchors.fill: parent
            visible: booth.state === BoothController.FormatSelect
        }

        ShareScreen {
            anchors.fill: parent
            visible: booth.state === BoothController.Share
        }
    }
}
