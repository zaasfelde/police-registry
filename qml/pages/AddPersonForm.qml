import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

Rectangle {
    id: addPersonForm
    anchors.fill: parent
    color: "#E0E4E9"
    radius: 10
    border.color: "#7d98ab"
    border.width: 1
    clip: true

    // Сигналы
    signal closeRequested()
    signal saveRequested(var personData)

    // Свойства для цветов (будут установлены из Main.qml)
    property color colorBackground: "#c6cdd7"
    property color colorPrimary: "#001e38"
    property color colorSecondary: "#112F49"
    property color colorAccent: "#BAC1CC"
    property color colorHover: "#557FA3"
    property color colorPressed: "#375D7F"
    property color colorTextLight: "#BAC1CC"
    property color colorTextDark: "#2c3e50"
    property color colorSrchButton: "#112F49"

    ColumnLayout {
        anchors {
            fill: parent
            margins: 20
        }
        spacing: 15

        // Заголовок
        Text {
            text: "📝 Добавление личности"
            font.pixelSize: 24
            font.bold: true
            color: colorTextDark
            Layout.alignment: Qt.AlignHCenter
        }

        // Основная информация
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            // Блок с фотографией
            ColumnLayout {
                spacing: 10

                Rectangle {
                    id: photoPlaceholder
                    Layout.preferredWidth: 400
                    Layout.preferredHeight: 500
                    color: "#BAC1CC"
                    radius: 5
                    border.color: "#7d98ab"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "🖼️ Фото"
                        color: colorTextDark
                        font.pixelSize: 22
                    }
                }

                Rectangle {
                    id: addPhotoBtn
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 40
                    radius: 25
                    color: {
                        if (addPhotoMa.pressed) return colorPressed
                        if (addPhotoMa.containsMouse) return colorHover
                        return colorSecondary
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Добавить фото"
                        color: colorTextLight
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: addPhotoMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            console.log("Добавление фото...")
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }

                // Судимость
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CheckBox {
                        id: criminalRecordCheck
                        checked: false
                    }

                    Text {
                        text: "Имеет судимость"
                        color: colorTextDark
                        font.pixelSize: 18
                    }
                }
            }

            // Поля ввода
            ColumnLayout {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                spacing: 12

                // Layout с полями ввода
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        text: "Фамилия:"
                        color: colorTextDark
                        font.pixelSize: 18
                        font.bold: true
                    }

                    TextField {
                        id: surnameField
                        Layout.preferredHeight: 35;
                        color: "black"
                        Layout.fillWidth: true
                        placeholderText: "Введите фамилию"
                        font.pixelSize: 18
                        background: Rectangle {
                            radius: 5
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"
                        }
                    }

                    Text {
                        text: "Имя:"
                        color: colorTextDark
                        font.pixelSize: 18
                        font.bold: true
                    }

                    TextField {
                        id: nameField
                        Layout.preferredHeight: 35;
                        color: "black"
                        Layout.fillWidth: true
                        placeholderText: "Введите имя"
                        font.pixelSize: 18
                        background: Rectangle {
                            radius: 5
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"
                        }
                    }

                    Text {
                        text: "Отчество:"
                        color: colorTextDark
                        font.pixelSize: 18
                        font.bold: true
                    }

                    TextField {
                        id: patronymicField
                        Layout.preferredHeight: 35;
                        color: "black"
                        Layout.fillWidth: true
                        placeholderText: "Введите отчество"
                        font.pixelSize: 18
                        background: Rectangle {
                            radius: 5
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"
                        }
                    }

                    Text {
                        text: "Дата рождения:"
                        color: colorTextDark
                        font.pixelSize: 18
                        font.bold: true
                    }

                    TextField {
                        id: birthDateField
                        Layout.preferredHeight: 35;
                        color: "black"
                        Layout.fillWidth: true
                        placeholderText: "дд.мм.гггг"
                        font.pixelSize: 18
                        background: Rectangle {
                            radius: 5
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"
                        }
                    }

                    Text {
                        text: "Адрес: "
                        color: colorTextDark
                        font.pixelSize: 18
                        font.bold: true
                    }

                    TextField {
                        id: addressField
                        Layout.preferredHeight: 35;
                        color: "black"
                        Layout.fillWidth: true
                        placeholderText: "Введите адрес"
                        font.pixelSize: 18
                        background: Rectangle {
                            radius: 5
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"
                        }
                    }

                    Text {
                        text: "Номер телефона: "
                        color: colorTextDark
                        font.pixelSize: 18
                        font.bold: true
                    }

                    TextField {
                        id: phoneField
                        Layout.preferredHeight: 35;
                        color: "black"
                        Layout.fillWidth: true
                        placeholderText: "Введите номер телефона"
                        font.pixelSize: 18
                        background: Rectangle {
                            radius: 5
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"
                        }
                    }

                    Text {
                        text: "Описание: "
                        color: colorTextDark
                        font.pixelSize: 18
                        font.bold: true
                    }

                    TextField {
                        id: descriptionField
                        Layout.preferredHeight: 35;
                        color: "black"
                        Layout.fillWidth: true
                        placeholderText: "Введите описание"
                        font.pixelSize: 18
                        background: Rectangle {
                            radius: 5
                            border.color: "#7d98ab"
                            border.width: 1
                            color: "white"
                        }
                    }
                }

                // Статус
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        text: "Статус:"
                        color: colorTextDark
                        font.pixelSize: 18
                        font.bold: true
                    }

                    // Кастомный comboBox
                    Rectangle {
                        id: statusComboBox
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 5
                        border.color: "#7d98ab"
                        border.width: 1
                        color: "white"

                        property var model: ["Подозреваемый", "Обвиняемый", "Свидетель", "Потерпевший"]
                        property int currentIndex: 0
                        property string currentText: model[currentIndex]

                        Text {
                            id: comboDisplayText
                            anchors {
                                left: parent.left
                                leftMargin: 10
                                verticalCenter: parent.verticalCenter
                            }
                            text: statusComboBox.currentText
                            color: colorTextDark
                            font.pixelSize: 18
                        }

                        Rectangle {
                            id: dropdownArrow
                            width: 20; height: 20
                            radius: 3
                            color: colorSecondary
                            anchors {
                                right: parent.right
                                rightMargin: 10
                                verticalCenter: parent.verticalCenter
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "▼"
                                color: colorTextLight
                                font.pixelSize: 10
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                statusDropdown.visible = !statusDropdown.visible
                            }
                            cursorShape: Qt.PointingHandCursor
                        }

                        // Выпадающий список
                        Rectangle {
                            id: statusDropdown
                            width: parent.width; height: 120
                            anchors {
                                top: parent.bottom
                                topMargin: 2
                            }
                            color: "white"
                            border.color: "#7d98ab"
                            border.width: 1
                            radius: 5
                            visible: false
                            z: 1000

                            Column {
                                anchors.fill: parent
                                spacing: 1

                                Repeater {
                                    model: statusComboBox.model

                                    Rectangle {
                                        width: statusDropdown.width; height: 40
                                        color: dropdownItemMa.containsMouse ? colorHover : "white"

                                        Text {
                                            anchors {
                                                left: parent.left
                                                leftMargin: 10
                                                verticalCenter: parent.verticalCenter
                                            }
                                            text: modelData
                                            color: colorTextDark
                                            font.pixelSize: 14
                                        }

                                        MouseArea {
                                            id: dropdownItemMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            onClicked: {
                                                statusComboBox.currentIndex = index
                                                statusComboBox.currentText = modelData
                                                statusDropdown.visible = false
                                            }
                                            cursorShape: Qt.PointingHandCursor
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Кнопки действий
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            // Кнопка "Сохранить"
            Rectangle {
                id: saveBtn
                width: 120
                height: 40
                radius: 20
                color: {
                    if (saveMa.pressed) return colorPressed
                    if (saveMa.containsMouse) return colorHover
                    return colorSecondary
                }

                Text {
                    anchors.centerIn: parent
                    text: "Сохранить"
                    color: colorTextLight
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    id: saveMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        savePerson()
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Кнопка "Отмена"
            Rectangle {
                id: cancelBtn
                width: 120
                height: 40
                radius: 20
                color: {
                    if (cancelMa.pressed) return "#E74C3C"
                    if (cancelMa.containsMouse) return "#EC7063"
                    return "#C0392B"
                }

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
                    onClicked: {
                        closeRequested()
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // Кнопка "Показать список"
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 10

            Rectangle {
                id: showListBtn
                width: saveBtn.width + cancelBtn.width + 10
                height: 40
                radius: 20
                color: {
                    if (showListMa.pressed) return colorPressed
                    if (showListMa.containsMouse) return colorHover
                    return colorSecondary
                }

                Text {
                    anchors.centerIn: parent
                    text: "Показать список"
                    color: colorTextLight
                    font.pixelSize: 16
                    font.bold: true
                }

                MouseArea {
                    id: showListMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        console.log("метод показа списка")
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }

    // Функция сохранения данных личности
    // В функцию savePerson() добавьте вызов к БД:
    function savePerson() {
        var personData = {
            name: nameField.text,
            surname: surnameField.text,
            patronymic: patronymicField.text,
            birthDate: birthDateField.text,
            status: statusComboBox.currentText,
            criminal_record: criminalRecordCheck.checked,
            address: addressField.text,
            phone: phoneField.text,
            description: descriptionField.text,
            caseNumber: "" // добавьте поле для номера дела
        }

        console.log("Сохранение данных:", JSON.stringify(personData))

        // Сохраняем в базу данных
        var success = dbManager.addPerson(personData)

        if (success) {
            console.log("Личность успешно сохранена в БД")
            // Очищаем поля
            nameField.text = ""
            surnameField.text = ""
            patronymicField.text = ""
            birthDateField.text = ""
            statusComboBox.currentIndex = 0
            criminalRecordCheck.checked = false
            addressField.text = ""
            phoneField.text = ""
            descriptionField.text = ""

            // Отправляем сигнал с данными
            saveRequested(personData)
            closeRequested()
        } else {
            console.log("Ошибка при сохранении личности в БД")
        }
    }
}
