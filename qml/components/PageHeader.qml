import QtQuick
import QtQuick.Layouts
import policedep

/*
 * Заголовок страницы: название, подпись и слот для действий.
 * Дочерние элементы автоматически попадают в правую часть.
 */
RowLayout {
    id: root

    property string title: ""
    property string subtitle: ""

    default property alias actions: actionsRow.data

    spacing: 12
    implicitHeight: 52

    Column {
        spacing: 2
        Layout.alignment: Qt.AlignVCenter

        Text {
            text: root.title
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontHeading
            font.bold: true
            elide: Text.ElideRight
        }

        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            elide: Text.ElideRight
        }
    }

    Item {
        Layout.fillWidth: true
    }

    RowLayout {
        id: actionsRow
        spacing: 8
        Layout.alignment: Qt.AlignVCenter
    }
}
