import QtQuick
import QtQuick.Controls
import policedep

/*
 * Поле поиска с иконкой.
 */
TextField {
    id: root

    implicitHeight: 38
    implicitWidth: 260
    leftPadding: 36
    rightPadding: 12
    verticalAlignment: TextInput.AlignVCenter
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontBody
    color: Theme.text
    placeholderTextColor: Theme.textFaint
    selectionColor: Theme.primary
    selectedTextColor: "#FFFFFF"

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: "🔍"
        font.pixelSize: 13
        opacity: 0.75
    }

    background: Rectangle {
        radius: Theme.radiusSm
        color: Theme.surface
        border.width: root.activeFocus ? 2 : 1
        border.color: root.activeFocus ? Theme.primary : Theme.border
    }
}
