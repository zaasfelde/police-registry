import QtQuick
import QtQuick.Controls
import policedep

/*
 * Панель настройки 2FA: QR-код и ключ для ручного ввода.
 */
Rectangle {
    id: root

    property string uri: ""
    property string secret: ""

    implicitHeight: 250
    radius: Theme.radius
    color: Theme.surfaceAlt
    border.color: Theme.border
    border.width: 1

    Row {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 18

        Rectangle {
            width: 200
            height: 200
            radius: Theme.radiusSm
            color: "#FFFFFF"
            border.color: Theme.border
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter

            QrCode {
                anchors.fill: parent
                anchors.margins: 8
                qrData: root.uri
            }
        }

        Column {
            width: parent.width - 236
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Text {
                text: "1. Откройте Google Authenticator (или другое приложение TOTP)"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
                width: parent.width
                wrapMode: Text.WordWrap
            }

            Text {
                text: "2. Отсканируйте QR-код или введите ключ вручную:"
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                width: parent.width
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width
                height: 34
                radius: Theme.radiusSm
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.secret
                    color: Theme.text
                    font.family: "Consolas"
                    font.pixelSize: Theme.fontBody
                    font.letterSpacing: 1.2
                }
            }

            Text {
                text: "3. Введите шестизначный код из приложения ниже."
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                width: parent.width
                wrapMode: Text.WordWrap
            }
        }
    }
}
