import QtQuick
import QtQuick.Layouts
import policedep

/*
 * Белая карточка с заголовком. Дочерние элементы попадают во внутренний
 * ColumnLayout, поэтому им можно задавать Layout.fillWidth.
 */
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""

    default property alias contentData: contentLayout.data

    implicitHeight: mainLayout.implicitHeight + 40
    radius: Theme.radius
    color: Theme.surface
    border.color: Theme.border
    border.width: 1

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: root.title !== ""

            Text {
                visible: root.icon !== ""
                text: root.icon
                font.pixelSize: 16
            }

            Column {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: root.title
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.bold: true
                }

                Text {
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    width: parent.width
                    elide: Text.ElideRight
                }
            }
        }

        ColumnLayout {
            id: contentLayout
            Layout.fillWidth: true
            spacing: 12
        }
    }
}
