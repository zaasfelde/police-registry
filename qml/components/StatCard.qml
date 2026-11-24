import QtQuick
import policedep

/*
 * Карточка показателя на дашборде.
 */
Rectangle {
    id: root

    property string title: ""
    property string value: "0"
    property string subtitle: ""
    property string icon: "📊"
    property color accent: Theme.primary

    implicitHeight: 108
    radius: Theme.radius
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    Row {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        Rectangle {
            width: 46
            height: 46
            radius: 13
            color: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.pixelSize: 20
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 60
            spacing: 2

            Text {
                text: root.value
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 25
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                text: root.title
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                elide: Text.ElideRight
                width: parent.width
            }

            Text {
                visible: root.subtitle !== ""
                text: root.subtitle
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                elide: Text.ElideRight
                width: parent.width
            }
        }
    }
}
