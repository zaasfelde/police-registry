import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Показ резервных кодов после включения или перегенерации 2FA.
 */
Dialog {
    id: root

    property var codes: []
    property string heading: "Резервные коды"
    property string description: "Сохраните коды в безопасном месте. Каждый код можно использовать один раз, если телефон с приложением недоступен."
    property string warning: "Коды больше не будут показаны."
    property string confirmText: "Я сохранил коды"

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 24
    width: 460
    parent: Overlay.overlay
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    background: Rectangle {
        radius: Theme.radiusLg
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
    }

    contentItem: ColumnLayout {
        spacing: 12

        Text {
            Layout.fillWidth: true
            text: root.heading
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontTitle
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            wrapMode: Text.WordWrap
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 10
            rowSpacing: 6

            Repeater {
                model: root.codes

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: Theme.radiusSm
                    color: Theme.surfaceAlt
                    border.color: Theme.border
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: Theme.text
                        font.family: "Consolas"
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        font.letterSpacing: 1.1
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.warning
            color: Theme.danger
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
            font.bold: true
        }
    }

    footer: Item {
        implicitHeight: 40

        AppButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: root.confirmText
            onClicked: root.close()
        }
    }

    function showCodes(list, titleText, descriptionText, warningText) {
        codes = list || []
        if (titleText)
            heading = titleText
        if (descriptionText)
            description = descriptionText
        if (warningText)
            warning = warningText
        open()
    }
}
