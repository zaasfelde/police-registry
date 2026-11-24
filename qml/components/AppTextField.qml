import QtQuick
import QtQuick.Controls
import policedep

/*
 * Поле ввода с подписью, подсказкой и ошибкой. Умеет показывать/скрывать
 * пароль и сообщать о нажатии Enter (сигнал accepted).
 */
Column {
    id: root

    property string label: ""
    property string placeholder: ""
    property bool required: false
    property bool password: false
    property string error: ""
    property string hint: ""
    property bool showLabel: true
    property alias text: field.text
    property alias textField: field
    property alias validator: field.validator
    property alias inputMask: field.inputMask
    property alias inputMethodHints: field.inputMethodHints
    property alias maximumLength: field.maximumLength
    property alias readOnly: field.readOnly
    property alias cursorPosition: field.cursorPosition

    signal accepted()
    signal editingFinished()

    readonly property bool hasError: error !== ""

    spacing: 6
    width: 260

    Text {
        visible: root.showLabel && root.label !== ""
        width: parent.width
        text: root.label + (root.required ? " *" : "")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.bold: true
        elide: Text.ElideRight
    }

    Rectangle {
        id: box
        width: parent.width
        height: 40
        radius: Theme.radiusSm
        color: root.readOnly ? Theme.surfaceAlt : Theme.surface
        border.width: field.activeFocus || root.hasError ? 2 : 1
        border.color: root.hasError ? Theme.danger : (field.activeFocus ? Theme.primary : Theme.border)

        TextField {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: root.password ? 76 : 12
            verticalAlignment: TextInput.AlignVCenter
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMedium
            color: Theme.text
            placeholderText: root.placeholder
            placeholderTextColor: Theme.textFaint
            selectionColor: Theme.primary
            selectedTextColor: "#FFFFFF"
            echoMode: root.password && !reveal.checked ? TextInput.Password : TextInput.Normal
            background: null
            onAccepted: root.accepted()
            onEditingFinished: root.editingFinished()
        }

        Text {
            id: reveal
            visible: root.password
            property bool checked: false
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: checked ? "Скрыть" : "Показать"
            color: Theme.primary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                onClicked: reveal.checked = !reveal.checked
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

    function forceActiveFocus() {
        field.forceActiveFocus()
    }

    function clear() {
        field.text = ""
    }
}
