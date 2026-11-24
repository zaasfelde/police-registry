import QtQuick
import policedep

/*
 * Небольшой календарь на месяц (неделя начинается с понедельника).
 * Реализован вручную, чтобы не зависеть от стиля Qt Quick Controls,
 * в котором Calendar может быть синглтоном.
 */
Column {
    id: root

    property date selectedDate: new Date()
    property date displayedMonth: new Date(selectedDate.getFullYear(), selectedDate.getMonth(), 1)

    signal chosen(date value)

    width: 308
    spacing: 8

    readonly property var monthNames: [
        "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь",
        "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь"
    ]
    readonly property var weekDays: ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]

    property var days: buildDays()

    function buildDays() {
        var year = displayedMonth.getFullYear()
        var month = displayedMonth.getMonth()
        var first = new Date(year, month, 1)
        var leading = (first.getDay() + 6) % 7
        var total = new Date(year, month + 1, 0).getDate()
        var today = new Date()
        var todayKey = today.getFullYear() + "-" + today.getMonth() + "-" + today.getDate()
        var selectedKey = selectedDate.getFullYear() + "-" + selectedDate.getMonth() + "-" + selectedDate.getDate()

        var result = []
        for (var i = 0; i < 42; ++i) {
            var dayNumber = i - leading + 1
            var date = new Date(year, month, dayNumber)
            var key = date.getFullYear() + "-" + date.getMonth() + "-" + date.getDate()
            result.push({
                date: date,
                label: String(date.getDate()),
                inMonth: dayNumber >= 1 && dayNumber <= total,
                today: key === todayKey,
                selected: key === selectedKey
            })
        }
        return result
    }

    function shiftMonth(delta) {
        displayedMonth = new Date(displayedMonth.getFullYear(), displayedMonth.getMonth() + delta, 1)
    }

    Row {
        width: parent.width
        spacing: 6

        AppButton {
            text: "‹"
            variant: "ghost"
            small: true
            width: 32
            onClicked: root.shiftMonth(-1)
        }

        Text {
            width: parent.width - 76
            text: root.monthNames[root.displayedMonth.getMonth()] + " " + root.displayedMonth.getFullYear()
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
        }

        AppButton {
            text: "›"
            variant: "ghost"
            small: true
            width: 32
            onClicked: root.shiftMonth(1)
        }
    }

    Row {
        width: parent.width

        Repeater {
            model: root.weekDays

            Text {
                width: root.width / 7
                text: modelData
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    Grid {
        width: parent.width
        columns: 7

        Repeater {
            model: root.days

            Rectangle {
                width: root.width / 7
                height: 34
                radius: Theme.radiusSm
                color: modelData.selected ? Theme.primary
                       : cellMouse.containsMouse && modelData.inMonth ? Theme.surfaceAlt : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: modelData.selected ? "#FFFFFF"
                           : modelData.inMonth ? (modelData.today ? Theme.primary : Theme.text)
                           : Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: modelData.today || modelData.selected
                }

                MouseArea {
                    id: cellMouse
                    anchors.fill: parent
                    enabled: modelData.inMonth
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.chosen(modelData.date)
                }
            }
        }
    }
}
