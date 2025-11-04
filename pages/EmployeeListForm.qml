import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

Rectangle {
    id: employeeListForm
    anchors.fill: parent
    color: "#E0E4E9"
    radius: 10
    border.color: "#7d98ab"
    border.width: 1
    clip: true

    // Сигналы
    signal closeRequested()
    signal employeeSelected(var employeeData)

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

    // Свойство для хранения списка сотрудников
    property var employees: []

    // Выпадающий список для фильтра званий (ВЫНЕСЕН НА КОРНЕВОЙ УРОВЕНЬ)
    Rectangle {
        id: rankFilterDropdown
        width: rankFilterCombo.width
        height: Math.min(450, rankFilterCombo.model.length * 45)
        color: "white"
        border.color: "#7d98ab"
        border.width: 1
        radius: 8
        visible: false
        z: 1000

        property point targetPosition: Qt.point(0, 0)

        x: targetPosition.x
        y: targetPosition.y + rankFilterCombo.height + 2

        ScrollView {
            anchors.fill: parent
            clip: true

            Column {
                width: parent.width
                spacing: 1

                Repeater {
                    model: rankFilterCombo.model

                    Rectangle {
                        width: rankFilterDropdown.width
                        height: 45
                        color: rankFilterItemMa.containsMouse ? colorHover : "white"

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 12
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData
                            color: rankFilterItemMa.containsMouse ? colorTextLight : colorTextDark
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: rankFilterItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                rankFilterCombo.currentIndex = index
                                rankFilterCombo.currentText = modelData
                                rankFilterDropdown.visible = false
                                filterEmployees()
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    // Выпадающий список для фильтра должностей (ВЫНЕСЕН НА КОРНЕВОЙ УРОВЕНЬ)
    Rectangle {
        id: positionFilterDropdown
        width: positionFilterCombo.width
        height: Math.min(300, positionFilterCombo.model.length * 45)
        color: "white"
        border.color: "#7d98ab"
        border.width: 1
        radius: 8
        visible: false
        z: 1000

        property point targetPosition: Qt.point(0, 0)

        x: targetPosition.x
        y: targetPosition.y + positionFilterCombo.height + 2

        ScrollView {
            anchors.fill: parent
            clip: true

            Column {
                width: parent.width
                spacing: 1

                Repeater {
                    model: positionFilterCombo.model

                    Rectangle {
                        width: positionFilterDropdown.width
                        height: 45
                        color: positionFilterItemMa.containsMouse ? colorHover : "white"

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 12
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData
                            color: positionFilterItemMa.containsMouse ? colorTextLight : colorTextDark
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: positionFilterItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                positionFilterCombo.currentIndex = index
                                positionFilterCombo.currentText = modelData
                                positionFilterDropdown.visible = false
                                filterEmployees()
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

        // Заголовок и кнопка закрытия
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "👥 Список сотрудников"
                font.pixelSize: 24
                font.bold: true
                color: colorTextDark
            }

            Item { Layout.fillWidth: true }

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
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                            closeRequested()
                    }
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
                        text: "Поиск по ФИО, званию или должности..."
                        color: "#7f8c8d"
                        font: parent.font
                        visible: !parent.text && !parent.activeFocus
                    }
                }
            }

            // Фильтр по званию
            Rectangle {
                id: rankFilterCombo
                Layout.preferredWidth: 200
                Layout.preferredHeight: 45
                radius: 8
                border.color: "#7d98ab"
                border.width: 1
                color: "white"

                property var model: ["Все звания", "Капитан внутренней службы", "Старший лейтенант внутренней службы", "Лейтенант внутренней службы", "Майор внутренней службы", "Подполковник внутренней службы", "Полковник внутренней службы"]
                property int currentIndex: 0
                property string currentText: model[currentIndex]

                Text {
                    id: rankFilterDisplay
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        right: rankFilterArrow.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: rankFilterCombo.currentText
                    color: colorTextDark
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: rankFilterArrow
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
                            var globalPos = mapToItem(employeeListForm, 0, 0)
                            rankFilterDropdown.targetPosition = Qt.point(globalPos.x, globalPos.y)
                            rankFilterDropdown.visible = !rankFilterDropdown.visible
                            positionFilterDropdown.visible = false
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Фильтр по должности
            Rectangle {
                id: positionFilterCombo
                Layout.preferredWidth: 250
                Layout.preferredHeight: 45
                radius: 8
                border.color: "#7d98ab"
                border.width: 1
                color: "white"

                property var model: ["Все должности", "Начальник отдела", "Заместитель начальника отдела", "Старший оперуполномоченный по особо важным делам", "Оперуполномоченный по особо важным делам", "Старший оперуполномоченный", "Криминалист"]
                property int currentIndex: 0
                property string currentText: model[currentIndex]

                Text {
                    id: positionFilterDisplay
                    anchors {
                        left: parent.left
                        leftMargin: 12
                        right: positionFilterArrow.left
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }
                    text: positionFilterCombo.currentText
                    color: colorTextDark
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: positionFilterArrow
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
                            var globalPos = mapToItem(employeeListForm, 0, 0)
                            positionFilterDropdown.targetPosition = Qt.point(globalPos.x, globalPos.y)
                            positionFilterDropdown.visible = !positionFilterDropdown.visible
                            rankFilterDropdown.visible = false
                        }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // Список сотрудников
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
                    id: employeeListView
                    anchors.fill: parent
                    model: filteredEmployees
                    spacing: 2

                    delegate: Rectangle {
                        id: employeeDelegate
                        width: employeeListView.width
                        height: 80
                        color: delegateMa.containsMouse ? "#D4EBFF" : (index % 2 === 0 ? "#F8F9F9" : "white")
                        border.color: "#EAECEE"
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 15

                            // Фото сотрудника
                            Rectangle {
                                width: 60
                                height: 60
                                radius: 30
                                color: "#BAC1CC"
                                border.color: "#7d98ab"
                                border.width: 1
                                anchors.verticalCenter: parent.verticalCenter
                                clip: true

                                Image {
                                    id: listEmployeePhoto
                                    anchors.fill: parent
                                    source: modelData.photo_path || ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true

                                    // Заглушка если фото нет
                                    Text {
                                        anchors.centerIn: parent
                                        text: "👤"
                                        font.pixelSize: 20
                                        visible: !modelData.photo_path || listEmployeePhoto.status === Image.Error
                                    }
                                }
                            }

                            // Основная информация
                            Column {
                                width: parent.width - 100
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Text {
                                    text: modelData.last_name + " " + modelData.name + " " + (modelData.patronymic || "")
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }

                                Row {
                                    width: parent.width
                                    spacing: 10

                                    Text {
                                        text: modelData.rank
                                        font.pixelSize: 14
                                        color: "#7f8c8d"
                                    }

                                    Text {
                                        text: "•"
                                        font.pixelSize: 14
                                        color: "#7f8c8d"
                                    }

                                    Text {
                                        text: modelData.position
                                        font.pixelSize: 14
                                        color: "#7f8c8d"
                                    }

                                    // Text {
                                    //     text: "•"
                                    //     font.pixelSize: 14
                                    //     color: "#7f8c8d"
                                    // }

                                    // Text {
                                    //     text: "Дата рождения: " + (modelData.birthDate || "не указана")
                                    //     font.pixelSize: 14
                                    //     color: "#7f8c8d"
                                    // }
                                }
                            }

                            // Иконка стрелки
                            // Text {
                            //     text: "➡️"
                            //     font.pixelSize: 16
                            //     anchors.verticalCenter: parent.verticalCenter
                            // }
                        }

                        MouseArea {
                            id: delegateMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                    employeeSelected(modelData)
                            }
                        }
                    }

                    // Заглушка при пустом списке
                    Rectangle {
                        width: employeeListView.width
                        height: 200
                        color: "transparent"
                        visible: employeeListView.count === 0

                        Column {
                            anchors.centerIn: parent
                            spacing: 15

                            Text {
                                text: "👥"
                                font.pixelSize: 48
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            Text {
                                text: "Сотрудники не найдены"
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
                    text: "Всего сотрудников: " + employees.length
                    font.pixelSize: 14
                    color: colorTextDark
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Отображено: " + employeeListView.count
                    font.pixelSize: 14
                    color: colorTextDark
                }
            }
        }
    }

    // Отфильтрованный список сотрудников
    property var filteredEmployees: []

    // Функция загрузки сотрудников из БД
    function loadEmployees() {
        employees = dbManager.getAllOfficers() || []
        filterEmployees()
        console.log("Загружено сотрудников:", employees.length)
    }

    // Функция фильтрации
    function filterEmployees() {
        var searchText = searchField.text.toLowerCase()
        var selectedRank = rankFilterCombo.currentIndex > 0 ? rankFilterCombo.currentText : ""
        var selectedPosition = positionFilterCombo.currentIndex > 0 ? positionFilterCombo.currentText : ""

        filteredEmployees = employees.filter(function(employee) {
            // Поиск по ФИО
            var fullName = (employee.last_name + " " + employee.name + " " + (employee.patronymic || "")).toLowerCase()
            var nameMatch = searchText === "" || fullName.includes(searchText)

            // Фильтр по званию
            var rankMatch = selectedRank === "" || employee.rank === selectedRank

            // Фильтр по должности
            var positionMatch = selectedPosition === "" || employee.position === selectedPosition

            return nameMatch && rankMatch && positionMatch
        })
    }

    Component.onCompleted: {
        loadEmployees()
    }

    // Закрываем выпадающие списки при клике вне их области
    MouseArea {
        anchors.fill: parent
        enabled: rankFilterDropdown.visible || positionFilterDropdown.visible
        onClicked: {
                rankFilterDropdown.visible = false
                positionFilterDropdown.visible = false
        }
    }
}
