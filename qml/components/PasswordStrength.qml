import QtQuick
import policedep

/*
 * Индикатор надёжности пароля + краткий чек-лист требований.
 */
Column {
    id: root

    property string password: ""
    property bool detailed: true

    readonly property bool longEnough: password.length >= 8
    readonly property bool hasLetter: /[A-Za-zА-Яа-яЁё]/.test(password)
    readonly property bool hasDigit: /[0-9]/.test(password)
    readonly property bool hasSpecial: /[^A-Za-zА-Яа-яЁё0-9]/.test(password)
    readonly property bool longStrong: password.length >= 12
    readonly property int score: (longEnough ? 1 : 0) + (hasLetter ? 1 : 0) + (hasDigit ? 1 : 0)
                                 + (hasSpecial || longStrong ? 1 : 0)

    spacing: 5
    width: 300

    Row {
        width: parent.width
        spacing: 4

        Repeater {
            model: 4

            Rectangle {
                width: (parent.width - 12) / 4
                height: 4
                radius: 2
                color: index < root.score
                       ? (root.score <= 1 ? Theme.danger : root.score === 2 ? Theme.warning : root.score === 3 ? "#5B9BD5" : Theme.success)
                       : Theme.surfaceMuted
            }
        }
    }

    Row {
        width: parent.width
        spacing: 8

        Text {
            text: "Надёжность: " + (root.score <= 1 ? "слабый" : root.score === 2 ? "средний" : root.score === 3 ? "хороший" : "надёжный")
            color: root.score <= 1 ? Theme.danger : root.score === 2 ? Theme.warning : Theme.success
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
            font.bold: true
        }

        Text {
            visible: root.detailed
            text: "Минимум 8 символов, буква и цифра"
            color: Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontCaption
            elide: Text.ElideRight
            width: parent.width - 130
        }
    }
}
