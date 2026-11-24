import QtQuick
import policedep

/*
 * Всплывающие уведомления. Слушает App.toast и показывает сообщение
 * внизу по центру, автоматически скрывая его через несколько секунд.
 */
Item {
    id: host

    property string message: ""
    property string kind: "info"
    property bool shown: false

    z: 10000

    Connections {
        target: App

        function onToast(text, kind) {
            host.show(text, kind)
        }
    }

    Rectangle {
        id: toast

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 26
        width: Math.min(parent.width - 80, 560)
        height: Math.max(46, messageText.implicitHeight + 24)
        radius: Theme.radius
        color: host.kind === "success" ? Theme.success
               : host.kind === "error" ? Theme.danger
               : host.kind === "warning" ? Theme.warning
               : Theme.sidebar
        opacity: host.shown ? 1 : 0
        scale: host.shown ? 1 : 0.96

        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Row {
            anchors.centerIn: parent
            width: parent.width - 32
            spacing: 10

            Text {
                text: host.kind === "success" ? "✓"
                      : host.kind === "error" ? "✕"
                      : host.kind === "warning" ? "⚠"
                      : "ℹ"
                color: "#FFFFFF"
                font.pixelSize: 16
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: messageText
                width: parent.width - 30
                text: host.message
                color: "#FFFFFF"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: Text.WordWrap
                verticalAlignment: Text.AlignVCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: host.shown
            cursorShape: Qt.PointingHandCursor
            onClicked: host.hide()
        }
    }

    Timer {
        id: hideTimer
        interval: 4200
        onTriggered: host.hide()
    }

    function show(text, type) {
        if (!text)
            return
        message = text
        kind = type || "info"
        shown = true
        hideTimer.restart()
    }

    function hide() {
        shown = false
        hideTimer.stop()
    }
}
