import QtQuick
import policedep

/*
 * Компактный цветной бейдж для статусов и ролей.
 */
Rectangle {
    id: root

    property string text: ""
    property color textColor: Theme.textMuted
    property color bgColor: Theme.neutralBg
    property bool small: false

    implicitWidth: label.implicitWidth + (small ? 14 : 18)
    implicitHeight: small ? 20 : 24
    radius: height / 2
    color: root.bgColor

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.textColor
        font.family: Theme.fontFamily
        font.pixelSize: root.small ? Theme.fontCaption : Theme.fontSmall
        font.bold: true
        elide: Text.ElideRight
    }
}
