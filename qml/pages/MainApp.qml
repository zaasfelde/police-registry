import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

Rectangle {
    id: mainApp
    anchors.fill: parent
    color: colorBackground

    // Сигнал для выхода
    signal logoutRequested()

    property color colorBackground: "#c6cdd7"
    property color colorPrimary: "#001e38"
    property color colorSecondary: "#112F49"
    property color colorAccent: "#BAC1CC"
    property color colorHover: "#557FA3"
    property color colorPressed: "#375D7F"
    property color colorTextLight: "#BAC1CC"
    property color colorTextDark: "#2c3e50"
    property color colorSrchButton: "#112F49"

    // Состояние отображения
    property bool showAddPersonForm: false
    property bool showAddEmployeeForm: false
    property bool showCaseListForm: false
    property bool showAddCaseForm: false
    property bool showPersonListForm: false

    // НОВОЕ: состояние для деталей сотрудника
    property bool showEmployeeDetailsForm: false

    Rectangle {
        anchors.fill: parent
        color: colorBackground

        // Левая панель навигации (без изменений)
        Rectangle {
            id: leftPanel
            width: 200
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
            }
            color: colorPrimary

            Column {
                anchors.fill: parent
                spacing: 12
                topPadding: 30

                // Кнопка "Личности" (без изменений)
                Rectangle {
                    id: identitiesBtn
                    width: leftPanel.width - 24
                    height: 50
                    radius: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: {
                        if (identitiesMa.pressed) return colorPressed
                        if (identitiesMa.containsMouse) return colorHover
                        return colorSecondary
                    }
                    border.color: colorAccent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "👤 Личности"
                        color: colorTextLight
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: identitiesMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            buttonClicked("Личности")
                        }
                        cursorShape: Qt.PointingHandCursor
                    }

                    ScaleAnimator {
                        id: identitiesScaleAnimation
                        target: identitiesBtn
                        from: 1
                        to: 0.95
                        duration: 100
                        onFinished: identitiesResetAnimation.start()
                    }

                    ScaleAnimator {
                        id: identitiesResetAnimation
                        target: identitiesBtn
                        from: 0.95
                        to: 1
                        duration: 100
                    }
                }

                // Кнопка "Дела" (без изменений)
                Rectangle {
                    id: casesBtn
                    width: leftPanel.width - 24
                    height: 50
                    radius: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: {
                        if (casesMa.pressed) return colorPressed
                        if (casesMa.containsMouse) return colorHover
                        return colorSecondary
                    }
                    border.color: colorAccent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "📁 Дела"
                        color: colorTextLight
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: casesMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            buttonClicked("Дела")
                        }
                        cursorShape: Qt.PointingHandCursor
                    }

                    ScaleAnimator {
                        id: casesScaleAnimation
                        target: casesBtn
                        from: 1
                        to: 0.95
                        duration: 100
                        onFinished: casesResetAnimation.start()
                    }

                    ScaleAnimator {
                        id: casesResetAnimation
                        target: casesBtn
                        from: 0.95
                        to: 1
                        duration: 100
                    }
                }

                // Кнопка "Материалы" (без изменений)
                Rectangle {
                    id: evidenceBtn
                    width: leftPanel.width - 24
                    height: 50
                    radius: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: {
                        if (evidenceMa.pressed) return colorPressed
                        if (evidenceMa.containsMouse) return colorHover
                        return colorSecondary
                    }
                    border.color: colorAccent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "📥 Материалы дела"
                        color: colorTextLight
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: evidenceMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            buttonClicked("Материалы дела")
                        }
                        cursorShape: Qt.PointingHandCursor
                    }

                    ScaleAnimator {
                        id: evidenceScaleAnimation
                        target: evidenceBtn
                        from: 1
                        to: 0.95
                        duration: 100
                        onFinished: evidenceResetAnimation.start()
                    }

                    ScaleAnimator {
                        id: evidenceResetAnimation
                        target: evidenceBtn
                        from: 0.95
                        to: 1
                        duration: 100
                    }
                }

                // Кнопка "Сотрудники"
                Rectangle {
                    id: employeesBtn
                    width: leftPanel.width - 24
                    height: 50
                    radius: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: {
                        if (employeesMa.pressed) return colorPressed
                        if (employeesMa.containsMouse) return colorHover
                        return colorSecondary
                    }
                    border.color: colorAccent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "💼 Сотрудники"
                        color: colorTextLight
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: employeesMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            buttonClicked("Сотрудники")
                        }
                        cursorShape: Qt.PointingHandCursor
                    }

                    ScaleAnimator {
                        id: employeesScaleAnimation
                        target: employeesBtn
                        from: 1
                        to: 0.95
                        duration: 100
                        onFinished: employeesResetAnimation.start()
                    }

                    ScaleAnimator {
                        id: employeesResetAnimation
                        target: employeesBtn
                        from: 0.95
                        to: 1
                        duration: 100
                    }
                }

                // Кнопка "Выйти" (без изменений)
                Rectangle {
                    id: logoutBtn
                    width: leftPanel.width - 24
                    height: 50
                    radius: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: {
                        if (logoutMa.pressed) return "#E74C3C"
                        if (logoutMa.containsMouse) return "#EC7063"
                        return "#C0392B"
                    }
                    border.color: colorAccent
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "🚪 Выйти"
                        color: colorTextLight
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: logoutMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            logoutRequested()
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }

        // Верхняя панель поиска (без изменений)
        Rectangle {
            id: topPanel
            height: 80
            anchors {
                left: leftPanel.right
                right: parent.right
                top: parent.top
            }
            color: "#d5dae0"
            border.color: "#7d98ab"
            border.width: 1

            Row {
                anchors.centerIn: parent
                spacing: 15

                Rectangle {
                    id: searchField
                    width: 500
                    height: 45
                    radius: 22
                    color: "#E0E4E9"
                    border.color: "#7d98ab"
                    border.width: 1

                    TextField {
                        id: searchInput
                        anchors {
                            fill: parent
                            margins: 10
                        }
                        background: Rectangle {
                            color: "transparent"
                            border.width: 0
                        }
                        font.pixelSize: 16
                        placeholderText: "Поиск..."
                        placeholderTextColor: "#7f8c8d"
                        color: colorTextDark
                        selectionColor: colorAccent
                        selectedTextColor: colorTextLight
                    }
                }

                Rectangle {
                    id: searchBtn
                    width: 120
                    height: 45
                    radius: 22
                    color: {
                        if (searchMa.pressed) return colorPressed
                        if (searchMa.containsMouse) return colorHover
                        return colorSrchButton
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "Найти"
                        color: colorTextLight
                        font.pixelSize: 16
                        font.bold: true
                    }

                    MouseArea {
                        id: searchMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            searchScaleAnimation.start()
                            console.log("Поиск:", searchInput.text)
                        }
                        cursorShape: Qt.PointingHandCursor
                    }

                    ScaleAnimator {
                        id: searchScaleAnimation
                        target: searchBtn
                        from: 1
                        to: 0.95
                        duration: 100
                        onFinished: searchResetAnimation.start()
                    }

                    ScaleAnimator {
                        id: searchResetAnimation
                        target: searchBtn
                        from: 0.95
                        to: 1
                        duration: 100
                    }
                }
            }
        }

        // Основная область контента
        Rectangle {
            id: mainContentArea
            anchors {
                left: leftPanel.right
                right: parent.right
                top: topPanel.bottom
                bottom: parent.bottom
                margins: 15
            }
            color: "#d5dae0"
            radius: 10
            border.color: "#7d98ab"
            border.width: 1

            // Стартовый экран
            Text {
                id: welcomeText
                anchors.centerIn: parent
                text: "Полицейский реестр"
                font.pixelSize: 32
                font.bold: false
                color: colorTextDark
                visible: !showAddPersonForm && !showAddEmployeeForm && !showCaseListForm && !showAddCaseForm && !showEmployeeDetailsForm
            }

            Text {
                id: underWelcomeText
                anchors.top: welcomeText.bottom
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
                text: "Учёт преступлений"
                font.pixelSize: 24
                font.bold: false
                color: colorTextDark
                opacity: 0.5
                visible: !showAddPersonForm && !showAddEmployeeForm && !showCaseListForm && !showAddCaseForm && !showEmployeeDetailsForm
            }

            // Загружаемая форма добавления личности (без изменений)
            Loader {
                id: personFormLoader
                anchors {
                    fill: parent
                    margins: 20
                }
                source: showAddPersonForm ? "AddPersonForm.qml" : ""
                visible: showAddPersonForm

                onLoaded: {
                    if (item) {
                        // Передаем цвета в форму
                        item.colorBackground = colorBackground
                        item.colorPrimary = colorPrimary
                        item.colorSecondary = colorSecondary
                        item.colorAccent = colorAccent
                        item.colorHover = colorHover
                        item.colorPressed = colorPressed
                        item.colorTextLight = colorTextLight
                        item.colorTextDark = colorTextDark
                        item.colorSrchButton = colorSrchButton

                        // Подключаем сигналы
                        item.closeRequested.connect(function() {
                            showAddPersonForm = false
                        })

                        item.saveRequested.connect(function(personData) {
                            console.log("Данные для сохранения в БД:", JSON.stringify(personData))
                            showAddPersonForm = false
                        })
                    }
                }
            }

            // Загружаемая форма списка сотрудников - ИСПРАВЛЕНА
            Loader {
                id: employeeFormLoader
                anchors {
                    fill: parent
                    margins: 20
                }
                source: showAddEmployeeForm ? "EmployeeListForm.qml" : ""
                visible: showAddEmployeeForm

                onLoaded: {
                    if (item) {
                        // Передаем цвета в форму
                        item.colorBackground = colorBackground
                        item.colorPrimary = colorPrimary
                        item.colorSecondary = colorSecondary
                        item.colorAccent = colorAccent
                        item.colorHover = colorHover
                        item.colorPressed = colorPressed
                        item.colorTextLight = colorTextLight
                        item.colorTextDark = colorTextDark
                        item.colorSrchButton = colorSrchButton

                        // Подключаем сигналы
                        item.closeRequested.connect(function() {
                            showAddEmployeeForm = false
                        })

                        item.employeeSelected.connect(function(employeeData) {
                            // Открываем форму деталей сотрудника и скрываем список
                            showEmployeeDetails(employeeData)
                            showAddEmployeeForm = false // ВАЖНО: скрываем список
                        })
                    }
                }
            }

            // Loader для деталей сотрудника - ИСПРАВЛЕН
            Loader {
                id: employeeDetailsLoader
                anchors {
                    fill: parent
                    margins: 20
                }
                source: showEmployeeDetailsForm ? "EmployeeDetailsForm.qml" : ""
                visible: showEmployeeDetailsForm

                onLoaded: {
                    if (item) {
                        item.colorBackground = colorBackground
                        item.colorPrimary = colorPrimary
                        item.colorSecondary = colorSecondary
                        item.colorAccent = colorAccent
                        item.colorHover = colorHover
                        item.colorPressed = colorPressed
                        item.colorTextLight = colorTextLight
                        item.colorTextDark = colorTextDark
                        item.colorSrchButton = colorSrchButton

                        item.closeRequested.connect(function() {
                            // При нажатии "Назад" показываем список сотрудников
                            showEmployeeDetailsForm = false
                            showAddEmployeeForm = true
                        })

                        item.editRequested.connect(function(employeeData) {
                            // Здесь можно открыть форму редактирования
                            console.log("Редактирование сотрудника:", employeeData)
                        })
                    }
                }
            }

            // Добавьте Loader для списка дел (без изменений)
            Loader {
                id: caseListLoader
                anchors {
                    fill: parent
                    margins: 20
                }
                source: showCaseListForm ? "CaseListForm.qml" : ""
                visible: showCaseListForm

                onLoaded: {
                    if (item) {
                        // Передаем цвета в форму
                        item.colorBackground = colorBackground
                        item.colorPrimary = colorPrimary
                        item.colorSecondary = colorSecondary
                        item.colorAccent = colorAccent
                        item.colorHover = colorHover
                        item.colorPressed = colorPressed
                        item.colorTextLight = colorTextLight
                        item.colorTextDark = colorTextDark
                        item.colorSrchButton = colorSrchButton

                        // Подключаем сигналы
                        item.closeRequested.connect(function() {
                            showCaseListForm = false
                        })

                        item.caseSelected.connect(function(caseData) {
                            // Здесь можно открыть детали дела
                            console.log("Выбрано дело:", caseData)
                        })

                        item.addCaseRequested.connect(function() {
                            showCaseListForm = false
                            showAddCaseForm = true
                        })
                    }
                }
            }

            // Добавьте Loader для формы добавления дела (без изменений)
            Loader {
                id: addCaseLoader
                anchors {
                    fill: parent
                    margins: 20
                }
                source: showAddCaseForm ? "AddCaseForm.qml" : ""
                visible: showAddCaseForm

                onLoaded: {
                    if (item) {
                        // Передаем цвета в форму
                        item.colorBackground = colorBackground
                        item.colorPrimary = colorPrimary
                        item.colorSecondary = colorSecondary
                        item.colorAccent = colorAccent
                        item.colorHover = colorHover
                        item.colorPressed = colorPressed
                        item.colorTextLight = colorTextLight
                        item.colorTextDark = colorTextDark
                        item.colorSrchButton = colorSrchButton

                        // Подключаем сигналы
                        item.closeRequested.connect(function() {
                            showAddCaseForm = false
                            showCaseListForm = true
                        })

                        item.saveRequested.connect(function(caseData) {
                            console.log("Дело сохранено:", JSON.stringify(caseData))
                            showAddCaseForm = false
                            showCaseListForm = true
                        })
                    }
                }
            }

            // В mainContentArea добавьте новый Loader для списка личностей:
            Loader {
                id: personListLoader
                anchors {
                    fill: parent
                    margins: 20
                }
                source: showPersonListForm ? "PersonListForm.qml" : ""
                visible: showPersonListForm

                onLoaded: {
                    if (item) {
                        // Передаем цвета в форму
                        item.colorBackground = colorBackground
                        item.colorPrimary = colorPrimary
                        item.colorSecondary = colorSecondary
                        item.colorAccent = colorAccent
                        item.colorHover = colorHover
                        item.colorPressed = colorPressed
                        item.colorTextLight = colorTextLight
                        item.colorTextDark = colorTextDark
                        item.colorSrchButton = colorSrchButton

                        // Подключаем сигналы
                        item.closeRequested.connect(function() {
                            showPersonListForm = false
                        })

                        item.personSelected.connect(function(personData) {
                            // Здесь можно открыть детали личности
                            console.log("Выбрана личность:", personData)
                        })

                        item.addPersonRequested.connect(function() {
                            showPersonListForm = false
                            showAddPersonForm = true
                        })
                    }
                }
            }
        }
    }

    function closeAllForms() {
        showAddEmployeeForm = false
        showAddPersonForm = false
        showCaseListForm = false
        showAddCaseForm = false
        showEmployeeDetailsForm = false // НОВОЕ: закрываем и детали сотрудника
        showPersonListForm = false
        console.log("Все формы были закрыты")
    }

    // Функция для обработки нажатия кнопок
    function buttonClicked(buttonName) {
        console.log(buttonName)

        // Запускаем анимацию для соответствующей кнопки
        switch(buttonName) {
            case "Личности":
                identitiesScaleAnimation.start()
                closeAllForms()
                showPersonListForm = true
                break
            case "Дела":
                casesScaleAnimation.start()
                closeAllForms()
                showCaseListForm = true
                break
            case "Материалы дела":
                evidenceScaleAnimation.start()
                closeAllForms()
                // показ формы
                break
            case "Сотрудники":
                employeesScaleAnimation.start()
                closeAllForms()
                showAddEmployeeForm = true
                break
        }
    }

    // Функция для показа деталей сотрудника - ИСПРАВЛЕНА
    function showEmployeeDetails(employeeData) {
        showEmployeeDetailsForm = true
        if (employeeDetailsLoader.item) {
            employeeDetailsLoader.item.updateEmployeeData(employeeData)
        }
    }
}
