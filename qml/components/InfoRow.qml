import QtQuick
import QtQuick.Layouts
import policedep

/*
 * Строка "подпись — значение" для карточек и профиля.
 */
RowLayout {
    id: root

    property string label: ""
    property var value: ""
    property int labelWidth: 150

    Layout.fillWidth: true
    spacing: 10

    Text {
        Layout.preferredWidth: root.labelWidth
        text: root.label
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.WordWrap
    }

    Text {
        Layout.fillWidth: true
        text: (root.value === undefined || root.value === null || root.value === "")
              ? "—" : String(root.value)
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        wrapMode: Text.WordWrap
    }
}
