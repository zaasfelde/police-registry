import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

Rectangle {
    id: addCaseForm
    anchors.fill: parent
    color: "#E0E4E9"
    radius: 10
    border.color: "#7d98ab"
    border.width: 1
    clip: true

    // Сигналы
    signal closeRequested()
    signal saveRequested(var caseData)

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

    // Список следователей
    property var investigators: []

    // Выпадающий список для следователей (ВЫНЕСЕН НА КОРНЕВОЙ УРОВЕНЬ)
    Rectangle {
        id: investigatorDropdown
        width: investigatorCombo.width
        height: Math.min(300, investigators.length * 45)
        color: "white"
        border.color: "#7d98ab"
        border.width: 1
        radius: 8
        visible: false
        z: 1000

        property point targetPosition: Qt.point(0, 0)

        x: targetPosition.x
        y: targetPosition.y + investigatorCombo.height + 2

        ScrollView {
            anchors.fill: parent
            clip: true

            Column {
                width: parent.width
                spacing: 1

                Repeater {
                    model: investigators

                    Rectangle {
                        width: investigatorDropdown.width
                        height: 45
                        color: investigatorItemMa.containsMouse ? colorHover : "white"

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 12
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData.text
                            color: investigatorItemMa.containsMouse ? colorTextLight : colorTextDark
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: investigatorItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                investigatorCombo.currentIndex = index
                                investigatorCombo.currentText = modelData.text
                                investigatorDropdown.visible = false
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    // Выпадающий список для статусов (ВЫНЕСЕН НА КОРНЕВОЙ УРОВЕНЬ)
    Rectangle {
        id: statusDropdown
        width: statusCombo.width
        height: Math.min(200, statusCombo.model.length * 45)
        color: "white"
        border.color: "#7d98ab"
        border.width: 1
        radius: 8
        visible: false
        z: 1000

        property point targetPosition: Qt.point(0, 0)

        x: targetPosition.x
        y: targetPosition.y + statusCombo.height + 2

        Column {
            width: parent.width
            spacing: 1

            Repeater {
                model: statusCombo.model

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
                            statusCombo.currentIndex = index
                            statusCombo.currentText = modelData
                            statusDropdown.visible = false
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        // Основной контейнер с ограниченной шириной для центрирования
        Rectangle {
            width: Math.min(600, parent.width * 0.8)
            height: contentLayout.height + 40
            color: "transparent"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20

            ColumnLayout {
                id: contentLayout
                width: parent.width
                spacing: 20
                anchors.top: parent.top

                // Заголовок
                Text {
                    text: "📁 Добавление уголовного дела"
                    font.pixelSize: 24
                    font.bold: true
                    color: colorTextDark
                    Layout.alignment: Qt.AlignHCenter
                }

                // Основная информация о деле
                ColumnLayout {
                    spacing: 15
                    Layout.fillWidth: true

                    // Номер дела
                    ColumnLayout {
                        spacing: 5
                        Layout.fillWidth: true

                        Text {
                            text: "Номер дела:*"
                            color: colorTextDark
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            radius: 8
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"

                            TextInput {
                                id: caseNumberField
                                anchors {
                                    fill: parent
                                    margins: 12
                                }
                                font.pixelSize: 16
                                color: colorTextDark
                                verticalAlignment: TextInput.AlignVCenter

                                Text {
                                    text: "Например: 12345"
                                    color: "#7f8c8d"
                                    font: parent.font
                                    visible: !parent.text && !parent.activeFocus
                                }
                            }
                        }
                    }

                    // Название дела
                    ColumnLayout {
                        spacing: 5
                        Layout.fillWidth: true

                        Text {
                            text: "Название дела:*"
                            color: colorTextDark
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            radius: 8
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"

                            TextInput {
                                id: titleField
                                anchors {
                                    fill: parent
                                    margins: 12
                                }
                                font.pixelSize: 16
                                color: colorTextDark
                                verticalAlignment: TextInput.AlignVCenter

                                Text {
                                    text: "Краткое описание дела"
                                    color: "#7f8c8d"
                                    font: parent.font
                                    visible: !parent.text && !parent.activeFocus
                                }
                            }
                        }
                    }

                    // Описание дела
                    ColumnLayout {
                        spacing: 5
                        Layout.fillWidth: true

                        Text {
                            text: "Описание дела:"
                            color: colorTextDark
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            radius: 8
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"

                            TextInput {
                                id: descriptionField
                                anchors {
                                    fill: parent
                                    margins: 12
                                }
                                font.pixelSize: 14
                                color: colorTextDark
                                wrapMode: TextInput.WordWrap
                                verticalAlignment: TextInput.AlignTop

                                Text {
                                    text: "Подробное описание обстоятельств дела..."
                                    color: "#7f8c8d"
                                    font: parent.font
                                    visible: !parent.text && !parent.activeFocus
                                }
                            }
                        }
                    }

                    // Дата открытия
                    ColumnLayout {
                        spacing: 5
                        Layout.fillWidth: true

                        Text {
                            text: "Дата возбуждения:*"
                            color: colorTextDark
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            radius: 8
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"

                            TextInput {
                                id: dateOpenedField
                                anchors {
                                    fill: parent
                                    margins: 12
                                }
                                font.pixelSize: 16
                                color: colorTextDark
                                verticalAlignment: TextInput.AlignVCenter

                                Text {
                                    text: "дд.мм.гггг"
                                    color: "#7f8c8d"
                                    font: parent.font
                                    visible: !parent.text && !parent.activeFocus
                                }
                            }
                        }
                    }

                    // Следователь
                    ColumnLayout {
                        spacing: 5
                        Layout.fillWidth: true

                        Text {
                            text: "Следователь:"
                            color: colorTextDark
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            id: investigatorCombo
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            radius: 8
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"

                            property int currentIndex: -1
                            property string currentText: currentIndex >= 0 ? investigators[currentIndex].text : "Выберите следователя"

                            Text {
                                id: investigatorDisplay
                                anchors {
                                    left: parent.left
                                    leftMargin: 12
                                    right: investigatorArrow.left
                                    rightMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                text: investigatorCombo.currentText
                                color: colorTextDark
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: investigatorArrow
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
                                    var globalPos = mapToItem(addCaseForm, 0, 0)
                                    investigatorDropdown.targetPosition = Qt.point(globalPos.x, globalPos.y)
                                    investigatorDropdown.visible = !investigatorDropdown.visible
                                    statusDropdown.visible = false
                                }
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }

                    // Статус дела
                    ColumnLayout {
                        spacing: 5
                        Layout.fillWidth: true

                        Text {
                            text: "Статус дела:*"
                            color: colorTextDark
                            font.pixelSize: 16
                            font.bold: true
                        }

                        Rectangle {
                            id: statusCombo
                            Layout.fillWidth: true
                            Layout.preferredHeight: 45
                            radius: 8
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"

                            property var model: ["Возбуждено", "Расследование", "Приостановлено"]
                            property int currentIndex: 0
                            property string currentText: model[currentIndex]

                            Text {
                                id: statusDisplay
                                anchors {
                                    left: parent.left
                                    leftMargin: 12
                                    right: statusArrow.left
                                    rightMargin: 10
                                    verticalCenter: parent.verticalCenter
                                }
                                text: statusCombo.currentText
                                color: colorTextDark
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                id: statusArrow
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
                                    var globalPos = mapToItem(addCaseForm, 0, 0)
                                    statusDropdown.targetPosition = Qt.point(globalPos.x, globalPos.y)
                                    statusDropdown.visible = !statusDropdown.visible
                                    investigatorDropdown.visible = false
                                }
                                cursorShape: Qt.PointingHandCursor
                            }
                        }
                    }
                }

                Text {
                    id: errorText
                    text: ""
                    color: "#E74C3C"
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignHCenter
                    visible: text !== ""
                }

                // Кнопки действий
                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 20

                    // Кнопка "Сохранить"
                    Rectangle {
                        width: 180
                        height: 45
                        radius: 22
                        color: saveMa.pressed ? colorPressed : (saveMa.containsMouse ? colorHover : colorSecondary)

                        Text {
                            anchors.centerIn: parent
                            text: "💾 Сохранить дело"
                            color: colorTextLight
                            font.pixelSize: 16
                            font.bold: true
                        }

                        MouseArea {
                            id: saveMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: saveCase()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Кнопка "Отмена"
                    Rectangle {
                        width: 180
                        height: 45
                        radius: 22
                        color: cancelMa.pressed ? "#E74C3C" : (cancelMa.containsMouse ? "#EC7063" : "#C0392B")

                        Text {
                            anchors.centerIn: parent
                            text: "Отмена"
                            color: colorTextLight
                            font.pixelSize: 16
                            font.bold: true
                        }

                        MouseArea {
                            id: cancelMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: closeRequested()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    // Функция сохранения дела
    function saveCase() {
        var caseNumber = caseNumberField.text.trim()
        var title = titleField.text.trim()
        var dateOpened = dateOpenedField.text.trim()

        if (!caseNumber || !title || !dateOpened) {
            errorText.text = "Заполните обязательные поля"
            return
        }

        var caseData = {
            caseNumber: caseNumber,
            title: title,
            description: descriptionField.text.trim(),
            dateOpened: dateOpened,
            dateClosed: "",
            status: statusCombo.currentText,
            investigatorId: investigatorCombo.currentIndex >= 0 ? investigators[investigatorCombo.currentIndex].id : 0
        }

        console.log("Сохранение дела:", JSON.stringify(caseData))

        // Сохраняем в базу данных
        var success = dbManager.addCase(caseData)

        if (success) {
            console.log("Дело успешно сохранено в БД")
            // Очищаем поля
            caseNumberField.text = ""
            titleField.text = ""
            descriptionField.text = ""
            dateOpenedField.text = ""
            statusCombo.currentIndex = 0
            investigatorCombo.currentIndex = -1
            errorText.text = ""

            // Отправляем сигнал с данными
            saveRequested(caseData)
        } else {
            errorText.text = "Ошибка при сохранении дела. Возможно, номер дела уже существует."
        }
    }

    // Функция загрузки следователей
    function loadInvestigators() {
        var officers = dbManager.getAllOfficers() || []
        investigators = officers.map(function(officer) {
            return {
                id: officer.officer_id,
                text: officer.last_name + " " + officer.name + " " + (officer.patronymic || "") + " - " + officer.rank
            }
        })
    }

    Component.onCompleted: {
        loadInvestigators()
    }

    // Закрываем выпадающие списки при клике вне их области
    MouseArea {
        anchors.fill: parent
        enabled: statusDropdown.visible || investigatorDropdown.visible
        onClicked: {
            statusDropdown.visible = false
            investigatorDropdown.visible = false
        }
    }
}
