import QtQuick
import QtQuick.Controls
import policedep

/*
 * Модальное подтверждение действия. Для удаления используйте
 * destructive: true — кнопка станет красной.
 */
Dialog {
    id: root

    property string heading: "Подтверждение"
    property string message: ""
    property string confirmText: "Подтвердить"
    property string cancelText: "Отмена"
    property string icon: "⚠️"
    property bool destructive: false

    signal confirmed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 24
    width: 440
    parent: Overlay.overlay
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    background: Rectangle {
        radius: Theme.radiusLg
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
    }

    contentItem: Column {
        spacing: 14

        Row {
            spacing: 12

            Text {
                text: root.icon
                font.pixelSize: 26
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                width: root.width - 120
                text: root.heading
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.bold: true
                wrapMode: Text.WordWrap
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Text {
            width: root.width - 48
            text: root.message
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
            wrapMode: Text.WordWrap
            lineHeight: 1.35
        }
    }

    footer: Item {
        implicitHeight: 40

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            AppButton {
                text: root.cancelText
                variant: "secondary"
                onClicked: root.close()
            }

            AppButton {
                text: root.confirmText
                variant: root.destructive ? "danger" : "primary"
                onClicked: {
                    root.close()
                    root.confirmed()
                }
            }
        }
    }

    function openConfirm(headingText, messageText, confirmLabel) {
        root.heading = headingText
        root.message = messageText
        if (confirmLabel)
            root.confirmText = confirmLabel
        root.open()
    }
}
