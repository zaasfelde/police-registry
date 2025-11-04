import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

Rectangle {
    id: registrationForm
    anchors.fill: parent
    color: "#E0E4E9"

    signal loginRequested()
    signal registrationSuccessful()

    property color colorBackground: "#c6cdd7"
    property color colorPrimary: "#001e38"
    property color colorSecondary: "#112F49"
    property color colorAccent: "#BAC1CC"
    property color colorHover: "#557FA3"
    property color colorPressed: "#375D7F"
    property color colorTextLight: "#BAC1CC"
    property color colorTextDark: "#2c3e50"
    property color colorSrchButton: "#112F49"

    // Выпадающий список для званий (на уровне корня)
    Rectangle {
        id: rankDropdown
        width: rankComboBox.width
        height: Math.min(300, rankComboBox.model.length * 45)
        color: "white"
        border.color: "#7d98ab"
        border.width: 1
        radius: 8
        visible: false
        z: 1000 // Высокий z-index для перекрытия всех элементов

        property point targetPosition: Qt.point(0, 0)

        x: targetPosition.x
        y: targetPosition.y + rankComboBox.height + 2

        ScrollView {
            anchors.fill: parent
            clip: true

            Column {
                width: parent.width
                spacing: 1

                Repeater {
                    model: rankComboBox.model

                    Rectangle {
                        width: rankDropdown.width
                        height: 45
                        color: rankDropdownItemMa.containsMouse ? colorHover : "white"

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 12
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData
                            color: rankDropdownItemMa.containsMouse ? colorTextLight : colorTextDark
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: rankDropdownItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                rankComboBox.currentIndex = index
                                rankComboBox.currentText = modelData
                                rankDropdown.visible = false
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    // Выпадающий список для должностей (на уровне корня)
    Rectangle {
        id: positionDropdown
        width: positionComboBox.width
        height: Math.min(250, positionComboBox.model.length * 45)
        color: "white"
        border.color: "#7d98ab"
        border.width: 1
        radius: 8
        visible: false
        z: 1000 // Высокий z-index для перекрытия всех элементов

        property point targetPosition: Qt.point(0, 0)

        x: targetPosition.x
        y: targetPosition.y + positionComboBox.height + 2

        ScrollView {
            anchors.fill: parent
            clip: true

            Column {
                width: parent.width
                spacing: 1

                Repeater {
                    model: positionComboBox.model

                    Rectangle {
                        width: positionDropdown.width
                        height: 45
                        color: positionDropdownItemMa.containsMouse ? colorHover : "white"

                        Text {
                            anchors {
                                left: parent.left
                                leftMargin: 12
                                right: parent.right
                                rightMargin: 12
                                verticalCenter: parent.verticalCenter
                            }
                            text: modelData
                            color: positionDropdownItemMa.containsMouse ? colorTextLight : colorTextDark
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            id: positionDropdownItemMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                positionComboBox.currentIndex = index
                                positionComboBox.currentText = modelData
                                positionDropdown.visible = false
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }

    ScrollView {
        anchors.fill: parent
        clip: true

        // Основной контейнер, который будет центрирован
        Rectangle {
            width: Math.min(600, parent.width * 0.8)
            height: contentLayout.height + 40 // + отступы
            color: "transparent"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 20

            ColumnLayout {
                id: contentLayout
                width: parent.width
                spacing: 20
                anchors.top: parent.top

                Text {
                    text: "👤 Регистрация сотрудника"
                    font.pixelSize: 28
                    font.bold: true
                    color: colorTextDark
                    Layout.alignment: Qt.AlignHCenter
                }

                // Основные поля ввода
                // Фамилия
                ColumnLayout {
                    spacing: 5
                    Layout.fillWidth: true

                    Text {
                        text: "Фамилия:*"
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
                            id: lastNameField
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            font.pixelSize: 16
                            color: colorTextDark
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                text: "Введите фамилию"
                                color: "#7f8c8d"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    // Имя
                    Text {
                        text: "Имя:*"
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
                            id: firstNameField
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            font.pixelSize: 16
                            color: colorTextDark
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                text: "Введите имя"
                                color: "#7f8c8d"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    // Отчество
                    Text {
                        text: "Отчество:"
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
                            id: patronymicField
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            font.pixelSize: 16
                            color: colorTextDark
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                text: "Введите отчество"
                                color: "#7f8c8d"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    // Дата рождения
                    Text {
                        text: "Дата рождения:"
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
                            id: birthDateField
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            font.pixelSize: 16
                            color: colorTextDark
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                text: "Введите дату рождения"
                                color: "#7f8c8d"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    // Стаж
                    Text {
                        text: "Стаж в годах:"
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
                            id: expField
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            font.pixelSize: 16
                            color: colorTextDark
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                text: "Укажите стаж в годах"
                                color: "#7f8c8d"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    // Табельный номер
                    Text {
                        text: "Табельный номер:"
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
                            id: numberField
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            font.pixelSize: 16
                            color: colorTextDark
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                text: "Табельный номер"
                                color: "#7f8c8d"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    // Логин
                    Text {
                        text: "Логин:*"
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
                            id: loginField
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            font.pixelSize: 16
                            color: colorTextDark
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                text: "Придумайте логин"
                                color: "#7f8c8d"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }

                    // Пароль
                    Text {
                        text: "Пароль:*"
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
                            id: passwordField
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            font.pixelSize: 16
                            color: colorTextDark
                            echoMode: TextInput.Password
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                text: "Придумайте пароль"
                                color: "#7f8c8d"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }
                    // Подтверждение пароля
                    Text {
                        text: "Повторите пароль:*"
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
                            id: confirmPasswordField
                            anchors {
                                fill: parent
                                margins: 12
                            }
                            font.pixelSize: 16
                            color: colorTextDark
                            echoMode: TextInput.Password
                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                text: "Повторите пароль"
                                color: "#7f8c8d"
                                font: parent.font
                                visible: !parent.text && !parent.activeFocus
                            }
                        }
                    }
                }

                // Звание и должность на одной строке
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Служебная информация"
                        color: colorTextDark
                        font.pixelSize: 18
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20

                        // Звание
                        ColumnLayout {
                            spacing: 5
                            Layout.fillWidth: true

                            Text {
                                text: "Звание:"
                                color: colorTextDark
                                font.pixelSize: 14
                                font.bold: true
                            }

                            // Кастомный ComboBox для званий
                            Rectangle {
                                id: rankComboBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 45
                                radius: 8
                                border.color: "#7d98ab"
                                border.width: 1
                                color: "white"

                                property var model: [
                                    "Капитан внутренней службы",
                                    "Старший лейтенант внутренней службы",
                                    "Лейтенант внутренней службы",
                                    "Младший лейтенант внутренней службы",
                                    "Майор внутренней службы",
                                    "Подполковник внутренней службы",
                                    "Полковник внутренней службы",
                                    "Генерал-майор внутренней службы",
                                    "Генерал-лейтенант внутренней службы",
                                    "Генерал-полковник внутренней службы",
                                    "Генерал внутренней службы Российской Федерации"
                                ]
                                property int currentIndex: 0
                                property string currentText: model[currentIndex]

                                Text {
                                    id: rankComboDisplayText
                                    anchors {
                                        left: parent.left
                                        leftMargin: 12
                                        right: dropdownArrow.left
                                        rightMargin: 10
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: rankComboBox.currentText
                                    color: colorTextDark
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    id: dropdownArrow
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
                                        var globalPos = mapToItem(registrationForm, 0, 0)
                                        rankDropdown.targetPosition = Qt.point(globalPos.x, globalPos.y)
                                        rankDropdown.visible = !rankDropdown.visible
                                        positionDropdown.visible = false // Закрываем другой список
                                    }
                                    cursorShape: Qt.PointingHandCursor
                                }
                            }
                        }

                        // Должность
                        ColumnLayout {
                            spacing: 5
                            Layout.fillWidth: true

                            Text {
                                text: "Должность:"
                                color: colorTextDark
                                font.pixelSize: 14
                                font.bold: true
                            }

                            // Кастомный ComboBox для должностей
                            Rectangle {
                                id: positionComboBox
                                Layout.fillWidth: true
                                Layout.preferredHeight: 45
                                radius: 8
                                border.color: "#7d98ab"
                                border.width: 1
                                color: "white"

                                property var model: [
                                    "Начальник отдела",
                                    "Заместитель начальника отдела",
                                    "Старший оперуполномоченный по особо важным делам",
                                    "Оперуполномоченный по особо важным делам",
                                    "Старший оперуполномоченный",
                                    "Криминалист"
                                ]
                                property int currentIndex: 0
                                property string currentText: model[currentIndex]

                                Text {
                                    id: positionComboDisplayText
                                    anchors {
                                        left: parent.left
                                        leftMargin: 12
                                        right: positionDropdownArrow.left
                                        rightMargin: 10
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: positionComboBox.currentText
                                    color: colorTextDark
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    id: positionDropdownArrow
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
                                        var globalPos = mapToItem(registrationForm, 0, 0)
                                        positionDropdown.targetPosition = Qt.point(globalPos.x, globalPos.y)
                                        positionDropdown.visible = !positionDropdown.visible
                                        rankDropdown.visible = false // Закрываем другой список
                                    }
                                    cursorShape: Qt.PointingHandCursor
                                }
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

                    // Кнопка "Зарегистрироваться"
                    Rectangle {
                        width: 200
                        height: 50
                        radius: 8
                        color: registerMa.pressed ? colorPressed : (registerMa.containsMouse ? colorHover : colorSecondary)

                        Text {
                            anchors.centerIn: parent
                            text: "Зарегистрироваться"
                            color: colorTextLight
                            font.pixelSize: 16
                            font.bold: true
                        }

                        MouseArea {
                            id: registerMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: register()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Кнопка "Отмена"
                    Rectangle {
                        width: 120
                        height: 50
                        radius: 8
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
                            onClicked: loginRequested()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }

                Text {
                    text: "Уже есть аккаунт? <a href='login'>Войти</a>"
                    font.pixelSize: 14
                    color: colorTextDark
                    Layout.alignment: Qt.AlignHCenter
                    linkColor: colorSecondary

                    MouseArea {
                        anchors.fill: parent
                        onClicked: loginRequested()
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    // Закрываем выпадающие списки при клике вне их области
    MouseArea {
        anchors.fill: parent
        enabled: rankDropdown.visible || positionDropdown.visible
        onClicked: {
            rankDropdown.visible = false
            positionDropdown.visible = false
        }
    }

    function register() {
        var lastName = lastNameField.text.trim()
        var firstName = firstNameField.text.trim()
        var login = loginField.text.trim()
        var password = passwordField.text.trim()
        var confirmPassword = confirmPasswordField.text.trim()

        if (!lastName || !firstName || !login || !password) {
            errorText.text = "Заполните обязательные поля"
            return
        }

        if (password !== confirmPassword) {
            errorText.text = "Пароли не совпадают"
            return
        }

        if (password.length < 4) {
            errorText.text = "Пароль должен быть не менее 4 символов"
            return
        }

        var officerData = {
            surname: lastName,
            name: firstName,
            patronymic: patronymicField.text.trim(),
            rank: rankComboBox.currentText,
            position: positionComboBox.currentText,
            birth_date: birthDateField.text,
            personnel_number: numberField.text,
            experience: expField.text,
            login: login,
            password: password
        }

        // Регистрируем через C++
        var success = dbManager.registerOfficer(officerData)

        if (success) {
            errorText.text = ""
            registrationSuccessful()
        } else {
            errorText.text = "Ошибка регистрации. Возможно, логин уже занят."
        }
    }

    function clearForm() {
        lastNameField.text = ""
        firstNameField.text = ""
        patronymicField.text = ""
        loginField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
        rankComboBox.currentIndex = 0
        positionComboBox.currentIndex = 0
        errorText.text = ""
    }
}
