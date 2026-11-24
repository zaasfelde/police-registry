import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

Rectangle {
    id: personListForm
    anchors.fill: parent
    color: "#E0E4E9"
    radius: 10
    border.color: "#7d98ab"
    border.width: 1
    clip: true

    // Сигналы
    signal closeRequested()
    signal personSelected(var personData)
    signal addPersonRequested()

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

    // Свойство для хранения списка личностей
    property var persons: []

    // Выпадающий список для статусов
    Rectangle {
        id: statusDropdown
        width: statusFilterCombo.width
        height: Math.min(200, statusFilterCombo.model.length * 45)
        color: "white"
        border.color: "#7d98ab"
        border.width: 1
        radius: 8
        visible: false
        z: 1000

        property point targetPosition: Qt.point(0, 0)

        x: targetPosition.x
        y: targetPosition.y + statusFilterCombo.height + 2

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
                            filterPersons()
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    // Выпадающий список для наличия судимости
    Rectangle {
        id: criminalRecordDropdown
        width: criminalRecordFilterCombo.width
        height: 135
        color: "white"
        border.color: "#7d98ab"
        border.width: 1
        radius: 8
        visible: false
        z: 1000

        property point targetPosition: Qt.point(0, 0)

        x: targetPosition.x
        y: targetPosition.y + criminalRecordFilterCombo.height + 2

        Column {
            width: parent.width
            spacing: 1

            Repeater {
                model: criminalRecordFilterCombo.model

                Rectangle {
                    width: criminalRecordDropdown.width
                    height: 45
                    color: criminalRecordItemMa.containsMouse ? colorHover : "white"

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 12
                            right: parent.right
                            rightMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        text: modelData
                        color: criminalRecordItemMa.containsMouse ? colorTextLight : colorTextDark
                        font.pixelSize: 14
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: criminalRecordItemMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            criminalRecordFilterCombo.currentIndex = index
                            criminalRecordFilterCombo.currentText = modelData
                            criminalRecordDropdown.visible = false
                            filterPersons()
                        }
                        cursorShape: Qt.PointingHandCursor
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
                text: "👤 Список личностей"
                font.pixelSize: 24
                font.bold: true
                color: colorTextDark
            }

            Item { Layout.fillWidth: true }

            // Кнопка "Добавить личность"
            Rectangle {
                width: 180
                height: 40
                radius: 20
                color: {
                    if (addPersonMa.pressed) return colorPressed
                    if (addPersonMa.containsMouse) return colorHover
                    return colorSecondary
                }

                Text {
                    anchors.centerIn: parent
                    text: "➕ Добавить личность"
                    color: colorTextLight
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: addPersonMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: addPersonRequested()
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
                        text: "Поиск по ФИО, адресу или описанию..."
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

                property var model: ["Все статусы", "Подозреваемый", "Потерпевший", "Свидетель"]
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
                        var globalPos = mapToItem(personListForm, 0, 0)
                        statusDropdown.targetPosition = Qt.point(globalPos.x, globalPos.y)
                        statusDropdown.visible = !statusDropdown.visible
                        criminalRecordDropdown.visible = false
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Фильтр по судимости
            Rectangle {
                id: criminalRecordFilterCombo
                Layout.preferredWidth: 180
                Layout.preferredHeight: 45
                radius: 8
                border.color: "#7d98ab"
                border.width: 1
                color: "white"

                property var model: ["Все", "С судимостью", "Без судимости"]
                property int currentIndex: 0
                property string currentText: model[currentIndex]

                Text {
                    id: criminalRecordFilterDisplay
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        right: criminalRecordFilterArrow.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: criminalRecordFilterCombo.currentText
                    color: colorTextDark
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: criminalRecordFilterArrow
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
                        var globalPos = mapToItem(personListForm, 0, 0)
                        criminalRecordDropdown.targetPosition = Qt.point(globalPos.x, globalPos.y)
                        criminalRecordDropdown.visible = !criminalRecordDropdown.visible
                        statusDropdown.visible = false
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // Список личностей
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
                    id: personListView
                    anchors.fill: parent
                    model: filteredPersons
                    spacing: 2

                    delegate: Rectangle {
                        id: personDelegate
                        width: personListView.width
                        height: 140
                        color: personMa.containsMouse ? "#D4EBFF" : (index % 2 === 0 ? "#F8F9F9" : "white")
                        border.color: "#EAECEE"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 15

                            // Иконка личности
                            Rectangle {
                                width: 80
                                height: 80
                                radius: 40
                                color: getStatusColor(modelData.status)
                                border.color: "#7d98ab"
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: getStatusIcon(modelData.status)
                                    color: "white"
                                    font.pixelSize: 24
                                    font.bold: true
                                }
                            }

                            // Основная информация
                            Column {
                                width: parent.width - 250
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    text: modelData.last_name + " " + modelData.name + " " + (modelData.patronymic || "")
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: "📅 " + (modelData.birth_date || "дата рождения не указана")
                                    font.pixelSize: 14
                                    color: "#7f8c8d"
                                }

                                Text {
                                    text: "📞 " + (modelData.phone || "телефон не указан")
                                    font.pixelSize: 14
                                    color: "#7f8c8d"
                                }

                                Text {
                                    text: "🏠 " + (modelData.address || "адрес не указан")
                                    font.pixelSize: 14
                                    color: "#7f8c8d"
                                    width: parent.width
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Text {
                                    text: modelData.description || "Описание отсутствует"
                                    font.pixelSize: 12
                                    color: "#7f8c8d"
                                    width: parent.width
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                    wrapMode: Text.WordWrap
                                }
                            }

                            // Статус и дополнительная информация
                            Column {
                                width: 150
                                spacing: 8
                                anchors.verticalCenter: parent.verticalCenter

                                // Статус
                                Rectangle {
                                    width: Math.min(parent.width, statusText.implicitWidth + 20)
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

                                // Судимость
                                Rectangle {
                                    width: Math.min(parent.width, criminalRecordText.implicitWidth + 20)
                                    height: 20
                                    radius: 10
                                    color: modelData.criminal_record ? "#E74C3C" : "#27AE60"
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    visible: criminalRecordFilterCombo.currentIndex === 0

                                    Text {
                                        id: criminalRecordText
                                        anchors.centerIn: parent
                                        text: modelData.criminal_record ? "Судимость" : "Чистая история"
                                        color: "white"
                                        font.pixelSize: 10
                                        font.bold: true
                                        leftPadding: 6
                                        rightPadding: 6
                                    }
                                }

                                // Номер дела
                                Text {
                                    text: modelData.case_number ? "Дело: " + modelData.case_number : "Дело не назначено"
                                    font.pixelSize: 11
                                    color: "#7f8c8d"
                                    width: parent.width
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }

                        MouseArea {
                            id: personMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                personSelected(modelData)
                            }
                        }
                    }

                    // Заглушка при пустом списке
                    Rectangle {
                        width: personListView.width
                        height: 200
                        color: "transparent"
                        visible: personListView.count === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 15

                            Text {
                                text: "👤"
                                font.pixelSize: 48
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Личности не найдены"
                                font.pixelSize: 18
                                color: colorTextDark
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Измените параметры поиска"
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
                    text: "Всего личностей: " + persons.length
                    font.pixelSize: 14
                    color: colorTextDark
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Отображено: " + personListView.count
                    font.pixelSize: 14
                    color: colorTextDark
                }
            }
        }
    }

    // Отфильтрованный список личностей
    property var filteredPersons: []

    // Функция загрузки личностей из БД
    function loadPersons() {
        persons = dbManager.getAllPersons() || []

        //отладка
        console.log("Данные личностей из БД")
        for (var i = 0; i < Math.min(persons.length, 3); i++) {
            var person = persons[i]
            console.log("person: ", person.last_name, person.name,
                        "criminal_record: ", person.criminal_record,
                        "type: ", typeof person.criminal_record)
        }
        console.log("Конец данных")

        filterPersons()
        console.log("Загружено личностей:", persons.length)
    }

    // Функция фильтрации
    function filterPersons() {
        var searchText = searchField.text.toLowerCase()
        var selectedStatus = statusFilterCombo.currentIndex > 0 ? statusFilterCombo.currentText : ""
        var criminalRecordFilter = criminalRecordFilterCombo.currentIndex

        filteredPersons = persons.filter(function(person) {
            // Поиск по ФИО, адресу и описанию
            var searchMatch = searchText === "" ||
                            person.last_name.toLowerCase().includes(searchText) ||
                            person.name.toLowerCase().includes(searchText) ||
                            (person.patronymic && person.patronymic.toLowerCase().includes(searchText)) ||
                            (person.address && person.address.toLowerCase().includes(searchText)) ||
                            (person.description && person.description.toLowerCase().includes(searchText))

            // Фильтр по статусу
            var statusMatch = selectedStatus === "" || person.status === selectedStatus

            // Фильтр по судимости - ИСПРАВЛЕННАЯ ЛОГИКА
            var criminalRecordMatch = true

            // Приводим criminal_record к булевому значению для надежности
            var hasCriminalRecord = false
            if (person.criminal_record === true || person.criminal_record === 1 || person.criminal_record === "true" || person.criminal_record === "1") {
                hasCriminalRecord = true
            }

            if (criminalRecordFilter === 1) { // "С судимостью"
                criminalRecordMatch = hasCriminalRecord === true
            } else if (criminalRecordFilter === 2) { // "Без судимости"
                criminalRecordMatch = hasCriminalRecord === false
            }
            // Если criminalRecordFilter === 0 ("Все"), то criminalRecordMatch остается true

            console.log("Фильтрация личности:", person.last_name,
                       "criminal_record:", person.criminal_record,
                       "type:", typeof person.criminal_record,
                       "hasCriminalRecord:", hasCriminalRecord,
                       "filter:", criminalRecordFilter,
                       "matches:", searchMatch && statusMatch && criminalRecordMatch)

            return searchMatch && statusMatch && criminalRecordMatch
        })

        console.log("Отфильтровано личностей:", filteredPersons.length)
    }

    // Функция для получения цвета статуса
    function getStatusColor(status) {
        switch(status) {
            case "Подозреваемый": return "#E74C3C" // красный
            case "Потерпевший": return "#3498DB" // синий
            case "Свидетель": return "#F39C12" // оранжевый
            default: return "#7F8C8D" // серый по умолчанию
        }
    }

    // Функция для получения иконки статуса
    function getStatusIcon(status) {
        switch(status) {
            case "Подозреваемый": return "🔍"
            case "Потерпевший": return "🛡️"
            case "Свидетель": return "👁️"
            default: return "👤"
        }
    }

    Component.onCompleted: {
        loadPersons()
    }

    // Закрываем выпадающие списки при клике вне их области
    MouseArea {
        anchors.fill: parent
        enabled: statusDropdown.visible || criminalRecordDropdown.visible
        onClicked: {
            statusDropdown.visible = false
            criminalRecordDropdown.visible = false
        }
    }
}
