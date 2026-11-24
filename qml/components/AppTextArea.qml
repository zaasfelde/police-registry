import QtQuick
import QtQuick.Controls
import policedep

/*
 * Многострочное поле ввода с подписью и ошибкой.
 */
Column {
    id: root

    property string label: ""
    property string placeholder: ""
    property bool required: false
    property string error: ""
    property string hint: ""
    property alias text: area.text
    property alias textArea: area
    property int preferredHeight: 96

    spacing: 6
    width: 300
    readonly property bool hasError: error !== ""

    Text {
        visible: root.label !== ""
        width: parent.width
        text: root.label + (root.required ? " *" : "")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.bold: true
    }

    Rectangle {
        width: parent.width
        height: root.preferredHeight
        radius: Theme.radiusSm
        color: Theme.surface
        border.width: area.activeFocus || root.hasError ? 2 : 1
        border.color: root.hasError ? Theme.danger : (area.activeFocus ? Theme.primary : Theme.border)

        ScrollView {
            anchors.fill: parent
            anchors.margins: 8
            clip: true

            TextArea {
                id: area
                placeholderText: root.placeholder
                placeholderTextColor: Theme.textFaint
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                wrapMode: TextArea.Wrap
                selectByMouse: true
                background: null
            }
        }
    }

    Text {
        visible: root.hasError || root.hint !== ""
        width: parent.width
        text: root.hasError ? root.error : root.hint
        color: root.hasError ? Theme.danger : Theme.textFaint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
    }
}
