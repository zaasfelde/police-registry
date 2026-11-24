import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

Rectangle {
    id: caseListForm
    anchors.fill: parent
    color: "#E0E4E9"
    radius: 10
    border.color: "#7d98ab"
    border.width: 1
    clip: true

    // Сигналы
    signal closeRequested()
    signal caseSelected(var caseData)
    signal addCaseRequested()

    // Свойства для цветов
    property color colorBackground: "#c6cdd7"
    property color colorPrimary: "#001e38"
    property color colorSecondary: "#112F49"
    property color colorAccent: "#BAC1CC"
    property color colorHover: "#557FA3"
    property color colorPressed: "#375D7F"
    property color colorTextLight: "#BAC1CC"
    property color colorTextDark: "#2c3e50"
    property color colorSrchButton: "#112F49"

    // Свойство для хранения списка дел
    property var cases: []

    // Выпадающий список для статусов (ВЫНЕСЕН НА КОРНЕВОЙ УРОВЕНЬ)
    Rectangle {
        id: statusDropdown
        width: statusFilterCombo.width
        height: Math.min(300, statusFilterCombo.model.length * 45)
        color: "white"
        border.color: "#7d98ab"
        border.width: 1
        radius: 8
        visible: false
        z: 1000

        property point targetPosition: Qt.point(0, 0)

        x: targetPosition.x
        y: targetPosition.y + statusFilterCombo.height + 2

        ScrollView {
            anchors.fill: parent
            clip: true

            Column {
                width: parent.width
                spacing: 1

                Repeater {
                    model: statusFilterCombo.model

                    Rectangle {
                        width: statusDropdown.width
                        height: 45
                        color: statusItemMa.containsMouse ? colorHover : "white"

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 12
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData
                            color: statusItemMa.containsMouse ? colorTextLight : colorTextDark
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: statusItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                statusFilterCombo.currentIndex = index
                                statusFilterCombo.currentText = modelData
                                statusDropdown.visible = false
                                filterCases()
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: 20
        }
        spacing: 15

        // Заголовок и кнопки
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "📁 Уголовные дела"
                font.pixelSize: 24
                font.bold: true
                color: colorTextDark
            }

            Item { Layout.fillWidth: true }

            // Кнопка "Добавить дело"
            Rectangle {
                width: 150
                height: 40
                radius: 20
                color: {
                    if (addCaseMa.pressed) return colorPressed
                    if (addCaseMa.containsMouse) return colorHover
                    return colorSecondary
                }

                Text {
                    anchors.centerIn: parent
                    text: "➕ Добавить дело"
                    color: colorTextLight
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: addCaseMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: addCaseRequested()
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Кнопка "Закрыть"
            Rectangle {
                width: 120
                height: 40
                radius: 20
                color: {
                    if (closeMa.pressed) return "#E74C3C"
                    if (closeMa.containsMouse) return "#EC7063"
                    return "#C0392B"
                }

                Text {
                    anchors.centerIn: parent
                    text: "Закрыть"
                    color: colorTextLight
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: closeRequested()
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // Панель поиска и фильтров
        RowLayout {
            Layout.fillWidth: true
            spacing: 15

            // Поле поиска
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                radius: 8
                border.color: "#7d98ab"
                border.width: 1
                color: "white"

                TextInput {
                    id: searchField
                    anchors {
                        fill: parent
                        margins: 12
                    }
                    font.pixelSize: 16
                    color: colorTextDark
                    verticalAlignment: TextInput.AlignVCenter

                    Text {
                        text: "Поиск по номеру дела, названию или следователю..."
                        color: "#7f8c8d"
                        font: parent.font
                        visible: !parent.text && !parent.activeFocus
                    }
                }
            }

            // Фильтр по статусу
            Rectangle {
                id: statusFilterCombo
                Layout.preferredWidth: 200
                Layout.preferredHeight: 45
                radius: 8
                border.color: "#7d98ab"
                border.width: 1
                color: "white"

                property var model: ["Все статусы", "Возбужденог", "Расследование", "Закрыто", "Приостановлено"]
                property int currentIndex: 0
                property string currentText: model[currentIndex]

                Text {
                    id: statusFilterDisplay
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        right: statusFilterArrow.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: statusFilterCombo.currentText
                    color: colorTextDark
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: statusFilterArrow
                    width: 30
                    height: 30
                    radius: 4
                    color: colorSecondary
                    anchors {
                        right: parent.right
                        rightMargin: 8
                        verticalCenter: parent.verticalCenter
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "▼"
                        color: colorTextLight
                        font.pixelSize: 12
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        // Вычисляем глобальную позицию комбобокса
                        var globalPos = mapToItem(caseListForm, 0, 0)
                        statusDropdown.targetPosition = Qt.point(globalPos.x, globalPos.y)
                        statusDropdown.visible = !statusDropdown.visible
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // Список дел
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "white"
            radius: 8
            border.color: "#7d98ab"
            border.width: 1

            ScrollView {
                anchors.fill: parent
                anchors.margins: 1
                clip: true

                ListView {
                    id: caseListView
                    anchors.fill: parent
                    model: filteredCases
                    spacing: 2

                    delegate: Rectangle {
                        id: caseDelegate
                        width: caseListView.width
                        height: 120
                        color: caseMa.containsMouse ? "#D4EBFF" : (index % 2 === 0 ? "#F8F9F9" : "white")
                        border.color: "#EAECEE"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15

                            // Иконка дела
                            Rectangle {
                                width: 70
                                height: 70
                                radius: 8
                                color: getStatusColor(modelData.status)
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: getStatusIcon(modelData.status)
                                    color: "white"
                                    font.pixelSize: 20
                                    font.bold: true
                                }
                            }

                            // Основная информация
                            Column {
                                width: parent.width - 200 // Уменьшил ширину, чтобы дать больше места статусу
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    text: "Дело № " + modelData.case_number + " - " + modelData.title
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: modelData.description || "Описание отсутствует"
                                    font.pixelSize: 14
                                    color: "#7f8c8d"
                                    width: parent.width
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                }

                                Row {
                                    width: parent.width
                                    spacing: 15

                                    Text {
                                        text: "📅 " + (modelData.date_opened || "дата не указана")
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                    }

                                    Text {
                                        text: "•"
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                    }

                                    Text {
                                        text: "👮 " + (modelData.investigator_name || "следователь не назначен")
                                        font.pixelSize: 12
                                        color: "#7f8c8d"
                                    }
                                }
                            }

                            Item {
                                width: 10; height: 1
                            }

                            // Статус и действия
                            Column {
                                width: 140 // Увеличил ширину для статуса
                                spacing: 5
                                anchors.verticalCenter: parent.verticalCenter

                                // Статус
                                Rectangle {
                                    width: Math.min(parent.width - 10, statusText.implicitWidth + 20) // Увеличил отступы
                                    height: 25
                                    radius: 12
                                    color: getStatusColor(modelData.status)
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    Text {
                                        id: statusText
                                        anchors.centerIn: parent
                                        text: modelData.status || "Не указан"
                                        color: "white"
                                        font.pixelSize: 11
                                        font.bold: true
                                        leftPadding: 8
                                        rightPadding: 8
                                    }
                                }

                                // Дата закрытия (если есть)
                                Text {
                                    text: modelData.date_closed ? "🔒 " + modelData.date_closed : ""
                                    font.pixelSize: 11
                                    color: "#7f8c8d"
                                    width: parent.width
                                    elide: Text.ElideRight
                                    visible: modelData.date_closed
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        MouseArea {
                            id: caseMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                caseSelected(modelData)
                            }
                        }
                    }

                    // Заглушка при пустом списке
                    Rectangle {
                        width: caseListView.width
                        height: 200
                        color: "transparent"
                        visible: caseListView.count === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 15

                            Text {
                                text: "📁"
                                font.pixelSize: 48
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Дела не найдены"
                                font.pixelSize: 18
                                color: colorTextDark
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Измените параметры поиска или добавьте новое дело"
                                font.pixelSize: 14
                                color: "#7f8c8d"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
            }
        }

        // Статистика внизу
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "transparent"

            RowLayout {
                anchors.fill: parent

                Text {
                    text: "Всего дел: " + cases.length
                    font.pixelSize: 14
                    color: colorTextDark
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Отображено: " + caseListView.count
                    font.pixelSize: 14
                    color: colorTextDark
                }
            }
        }
    }

    // Отфильтрованный список дел
    property var filteredCases: []

    // Функция загрузки дел из БД
    function loadCases() {
        cases = dbManager.getAllCases() || []
        filterCases()
        console.log("Загружено дел:", cases.length)
    }

    // Функция фильтрации
    function filterCases() {
        var searchText = searchField.text.toLowerCase()
        var selectedStatus = statusFilterCombo.currentIndex > 0 ? statusFilterCombo.currentText : ""

        filteredCases = cases.filter(function(caseItem) {
            // Поиск по номеру дела, названию и следователю
            var searchMatch = searchText === "" ||
                            caseItem.case_number.toLowerCase().includes(searchText) ||
                            caseItem.title.toLowerCase().includes(searchText) ||
                            (caseItem.investigator_name && caseItem.investigator_name.toLowerCase().includes(searchText))

            // Фильтр по статусу
            var statusMatch = selectedStatus === "" || caseItem.status === selectedStatus

            return searchMatch && statusMatch
        })
    }

    // Функция для получения цвета статуса
    function getStatusColor(status) {
        switch(status) {
            case "Возбуждено": return "#E74C3C" // красный
            case "Расследование": return "#F39C12" // оранжевый
            case "Закрыто": return "#27AE60" // зеленый
            case "Приостановлено": return "#95A5A6" // серый
            default: return "#7F8C8D" // серый по умолчанию
        }
    }

    // Функция для получения иконки статуса
    function getStatusIcon(status) {
        switch(status) {
            case "Возбуждено": return "🚨"
            case "Расследование": return "🔍"
            case "Закрыто": return "✅"
            case "Приостановлено": return "⏸️"
            default: return "📁"
        }
    }

    Component.onCompleted: {
        loadCases()
    }

    // Закрываем выпадающие списки при клике вне их области
    MouseArea {
        anchors.fill: parent
        enabled: statusDropdown.visible
        onClicked: {
            statusDropdown.visible = false
        }
    }
}
