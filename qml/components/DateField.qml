import QtQuick
import QtQuick.Controls
import policedep

/*
 * Поле даты с календарём. Значение хранится в ISO-формате yyyy-MM-dd,
 * чтобы его можно было без преобразований писать в SQLite.
 */
Column {
    id: root

    property string label: ""
    property bool required: false
    property string error: ""
    property string hint: ""
    property string value: ""
    property bool allowEmpty: true

    signal edited()

    spacing: 6
    width: 220

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
        id: box
        width: parent.width
        height: 40
        radius: Theme.radiusSm
        color: Theme.surface
        border.width: boxMouse.containsMouse ? 2 : 1
        border.color: root.hasError ? Theme.danger : (boxMouse.containsMouse ? Theme.primary : Theme.border)

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: clearButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.value ? Theme.formatDate(root.value) : "дд.мм.гггг"
            color: root.value ? Theme.text : Theme.textFaint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontMedium
        }

        Text {
            id: clearButton
            visible: root.allowEmpty && root.value !== ""
            anchors.right: calendarIcon.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            color: Theme.textFaint
            font.pixelSize: 12

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.value = ""
                    root.edited()
                }
            }
        }

        Text {
            id: calendarIcon
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "📅"
            font.pixelSize: 14
        }

        MouseArea {
            id: boxMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                var date = root.dateValue()
                calendarPopup.selectedDate = date
                miniCalendar.displayedMonth = new Date(date.getFullYear(), date.getMonth(), 1)
                calendarPopup.open()
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

    Popup {
        id: calendarPopup

        property date selectedDate: new Date()
        parent: box
        x: 0
        y: box.height + 6
        width: 332
        padding: 12
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        contentItem: Column {
            spacing: 10

            MiniCalendar {
                id: miniCalendar
                width: 308
                selectedDate: calendarPopup.selectedDate

                onChosen: function(value) {
                    root.value = Qt.formatDate(value, "yyyy-MM-dd")
                    calendarPopup.selectedDate = value
                    calendarPopup.close()
                    root.edited()
                }
            }

            Row {
                spacing: 8
                anchors.horizontalCenter: parent.horizontalCenter

                AppButton {
                    text: "Сегодня"
                    variant: "secondary"
                    small: true
                    onClicked: {
                        var today = new Date()
                        root.value = Qt.formatDate(today, "yyyy-MM-dd")
                        calendarPopup.close()
                        root.edited()
                    }
                }

                AppButton {
                    visible: root.allowEmpty
                    text: "Очистить"
                    variant: "ghost"
                    small: true
                    onClicked: {
                        root.value = ""
                        calendarPopup.close()
                        root.edited()
                    }
                }
            }
        }

        background: Rectangle {
            radius: Theme.radius
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
        }
    }

    function dateValue() {
        if (!root.value)
            return new Date()
        var parsed = new Date(root.value + "T00:00:00")
        return isNaN(parsed.getTime()) ? new Date() : parsed
    }

    function setToday() {
        root.value = Theme.todayIso()
    }

    function clear() {
        root.value = ""
    }
}
