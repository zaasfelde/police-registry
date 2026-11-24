import QtQuick
import policedep

/*
 * Заглушка для пустых списков.
 */
Column {
    id: root

    property string icon: "📭"
    property string title: "Ничего не найдено"
    property string description: ""
    property string actionText: ""

    signal actionClicked()

    spacing: 10
    width: 360

    Text {
        text: root.icon
        font.pixelSize: 42
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Text {
        width: parent.width
        text: root.title
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontTitle
        font.bold: true
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    Text {
        visible: root.description !== ""
        width: parent.width
        text: root.description
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
    }

    AppButton {
        visible: root.actionText !== ""
        text: root.actionText
        variant: "secondary"
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: root.actionClicked()
    }
}
