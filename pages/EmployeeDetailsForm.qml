import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15
import QtQuick.Dialogs

Rectangle {
    id: employeeDetailsForm
    anchors.fill: parent
    color: "#E0E4E9"
    radius: 10
    border.color: "#7d98ab"
    border.width: 1
    clip: true

    // Сигналы
    signal closeRequested()
    signal editRequested(var employeeData)

    // Свойства
    property color colorBackground: "#c6cdd7"
    property color colorPrimary: "#001e38"
    property color colorSecondary: "#112F49"
    property color colorAccent: "#BAC1CC"
    property color colorHover: "#557FA3"
    property color colorPressed: "#375D7F"
    property color colorTextLight: "#BAC1CC"
    property color colorTextDark: "#2c3e50"
    property color colorSrchButton: "#112F49"

    // Данные сотрудника
    property var employeeData: ({})

    Column {
        anchors {
            fill: parent
            margins: 20
        }
        spacing: 20

        // Заголовок и кнопки
        Item {
            width: parent.width
            height: 50

            Text {
                id: titleText
                text: "👤 Карточка сотрудника"
                font.pixelSize: 24
                font.bold: true
                color: colorTextDark
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            // Кнопка "Назад" - правая кнопка
            Rectangle {
                id: backButton
                width: 120
                height: 40
                radius: 20
                color: {
                    if (backMa.pressed) return "#E74C3C"
                    if (backMa.containsMouse) return "#EC7063"
                    return "#C0392B"
                }
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "Назад"
                    color: colorTextLight
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: backMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: closeRequested()
                    cursorShape: Qt.PointingHandCursor
                }
            }

            // Кнопка "Редактировать" - слева от кнопки "Назад"
            Rectangle {
                id: editButton
                width: 140
                height: 40
                radius: 20
                color: {
                    if (editMa.pressed) return colorPressed
                    if (editMa.containsMouse) return colorHover
                    return colorSecondary
                }
                anchors.right: backButton.left
                anchors.rightMargin: 15
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: "Редактировать"
                    color: colorTextLight
                    font.pixelSize: 14
                    font.bold: true
                }

                MouseArea {
                    id: editMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: editRequested(employeeData)
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // Основной контент
        Row {
            width: parent.width
            height: parent.height - 80
            spacing: 30

            // Левая колонка - фото и основная информация
            Column {
                width: 300
                height: parent.height
                spacing: 20

                // Фото сотрудника
                Rectangle {
                    id: photoContainer
                    width: 250
                    height: 300
                    color: employeePhoto.source === "" ? "#BAC1CC" : "transparent"
                    radius: 10
                    border.color: "#7d98ab"
                    border.width: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    // Изображение сотрудника
                    Image {
                        id: employeePhoto
                        anchors.fill: parent
                        anchors.margins: 2
                        source: employeeData.photo_path || ""
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        cache: false

                        // Заглушка если фото нет
                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            visible: employeePhoto.source === "" || employeePhoto.status === Image.Error

                            Column {
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    text: "👤"
                                    font.pixelSize: 48
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                Text {
                                    text: "Фотография\nне загружена"
                                    font.pixelSize: 14
                                    color: colorTextDark
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    horizontalAlignment: Text.AlignCenter
                                }
                            }
                        }
                    }

                    // Индикатор загрузки
                    Rectangle {
                        anchors.fill: parent
                        color: "#80000000"
                        visible: employeePhoto.status === Image.Loading

                        Text {
                            anchors.centerIn: parent
                            text: "Загрузка..."
                            color: "white"
                            font.pixelSize: 16
                        }
                    }
                }

                // Статус и действия
                Column {
                    width: parent.width
                    spacing: 10

                    // Кнопка "Изменить фото"
                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 10
                        color: {
                            if (changePhotoMa.pressed) return colorPressed
                            if (changePhotoMa.containsMouse) return colorHover
                            return colorSecondary
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "📷 Изменить фото"
                            color: colorTextLight
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            id: changePhotoMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                fileDialog.open()
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Кнопка "Удалить фото"
                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 10
                        color: {
                            if (removePhotoMa.pressed) return "#E74C3C"
                            if (removePhotoMa.containsMouse) return "#EC7063"
                            return "#C0392B"
                        }
                        visible: employeePhoto.source !== "" && employeePhoto.status !== Image.Error

                        Text {
                            anchors.centerIn: parent
                            text: "🗑️ Удалить фото"
                            color: colorTextLight
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            id: removePhotoMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                removePhoto()
                            }
                            cursorShape: Qt.PointingHandCursor
                        }
                    }

                    // Информация о фото
                    Rectangle {
                        width: parent.width
                        height: 60
                        color: "transparent"
                        visible: employeePhoto.source !== "" && employeePhoto.status !== Image.Error

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            // Text {
                            //     text: "Размер: " + (employeePhoto.sourceSize.width + "×" + employeePhoto.sourceSize.height)
                            //     font.pixelSize: 12
                            //     color: colorTextDark
                            //     anchors.horizontalCenter: parent.horizontalCenter
                            // }

                            // Text {
                            //     text: "Файл: " + getFileName(employeePhoto.source)
                            //     font.pixelSize: 12
                            //     color: colorTextDark
                            //     anchors.horizontalCenter: parent.horizontalCenter
                            //     elide: Text.ElideMiddle
                            //     maximumLineCount: 1
                            //     width: parent.width
                            // }
                        }
                    }
                }
            }

            // Правая колонка - детальная информация
            Column {
                width: parent.width - 330
                height: parent.height
                spacing: 15

                // Личная информация
                Rectangle {
                    width: parent.width
                    height: 200
                    color: "white"
                    radius: 8
                    border.color: "#7d98ab"
                    border.width: 1

                    Column {
                        anchors {
                            fill: parent
                            margins: 15
                        }
                        spacing: 10

                        Text {
                            text: "📋 Личная информация"
                            font.pixelSize: 18
                            font.bold: true
                            color: colorTextDark
                            width: parent.width
                        }

                        // Сетка информации
                        Grid {
                            width: parent.width
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10

                            // Колонка 1 - заголовки
                            Column {
                                width: (parent.width - 20) / 2
                                spacing: 10

                                Text {
                                    text: "Фамилия:"
                                    color: colorTextDark
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Имя:"
                                    color: colorTextDark
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Отчество:"
                                    color: colorTextDark
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Дата рождения:"
                                    color: colorTextDark
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            // Колонка 2 - значения
                            Column {
                                width: (parent.width - 20) / 2
                                spacing: 10

                                Text {
                                    text: employeeData.last_name || "не указано"
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: employeeData.name || "не указано"
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: employeeData.patronymic || "не указано"
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: employeeData.birth_date || "не указана"
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // Служебная информация
                Rectangle {
                    width: parent.width
                    height: 150
                    color: "white"
                    radius: 8
                    border.color: "#7d98ab"
                    border.width: 1

                    Column {
                        anchors {
                            fill: parent
                            margins: 15
                        }
                        spacing: 10

                        Text {
                            text: "💼 Служебная информация"
                            font.pixelSize: 18
                            font.bold: true
                            color: colorTextDark
                            width: parent.width
                        }

                        // Сетка информации
                        Grid {
                            width: parent.width
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10

                            // Колонка 1 - заголовки
                            Column {
                                width: (parent.width - 20) / 2
                                spacing: 10

                                Text {
                                    text: "Звание:"
                                    color: colorTextDark
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Должность:"
                                    color: colorTextDark
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Табельный номер:"
                                    color: colorTextDark
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            // Колонка 2 - значения
                            Column {
                                width: (parent.width - 20) / 2
                                spacing: 10

                                Text {
                                    text: employeeData.rank || "не указано"
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: employeeData.position || "не указано"
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: employeeData.personnel_number || "не назначен"
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // Дополнительная информация
                Rectangle {
                    width: parent.width
                    height: 120
                    color: "white"
                    radius: 8
                    border.color: "#7d98ab"
                    border.width: 1

                    Column {
                        anchors {
                            fill: parent
                            margins: 15
                        }
                        spacing: 10

                        Text {
                            text: "📊 Дополнительная информация"
                            font.pixelSize: 18
                            font.bold: true
                            color: colorTextDark
                            width: parent.width
                        }

                        // Сетка информации
                        Grid {
                            width: parent.width
                            columns: 2
                            columnSpacing: 20
                            rowSpacing: 10

                            // Колонка 1 - заголовки
                            Column {
                                width: (parent.width - 20) / 2
                                spacing: 10

                                Text {
                                    text: "Дата приема:"
                                    color: colorTextDark
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Стаж (в годах):"
                                    color: colorTextDark
                                    font.bold: true
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }

                            // Колонка 2 - значения
                            Column {
                                width: (parent.width - 20) / 2
                                spacing: 10

                                Text {
                                    text: employeeData.hire_date || "не указана"
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: employeeData.experience || "не указан"
                                    color: colorTextDark
                                    width: parent.width
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Диалог выбора файла (современная версия)
    FileDialog {
        id: fileDialog
        title: "Выберите фотографию сотрудника"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Изображения (*.png *.jpg *.jpeg *.bmp *.gif)", "Все файлы (*)"]
        onAccepted: {
            if (fileDialog.selectedFile) {
                var fileUrl = fileDialog.selectedFile
                console.log("Выбран файл:", fileUrl)
                loadPhoto(fileUrl)
            } else {
                console.log("Файл не выбран")
            }
        }
        onRejected: {
            console.log("Выбор фото отменен")
        }
    }

    // Попап для сообщений
    Popup {
        id: messagePopup
        anchors.centerIn: Overlay.overlay
        width: 300
        height: 100
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Rectangle {
            anchors.fill: parent
            color: "white"
            radius: 10
            border.color: "#7d98ab"
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    id: messageText
                    font.pixelSize: 16
                    color: colorTextDark
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Rectangle {
                    width: 100
                    height: 35
                    radius: 8
                    color: colorSecondary
                    anchors.horizontalCenter: parent.horizontalCenter

                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        color: colorTextLight
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: messagePopup.close()
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
        }
    }

    // Функция обновления данных
    function updateEmployeeData(newData) {
        employeeData = newData
        // Загружаем фото если есть путь
        if (employeeData.photo_path) {
            employeePhoto.source = employeeData.photo_path
        } else {
            employeePhoto.source = ""
        }
    }

    // Функция загрузки фото
    function loadPhoto(fileUrl) {
        if (fileUrl) {
            // Сохраняем путь к фото в БД
            var success = dbManager.updateEmployeePhoto(employeeData.officer_id, fileUrl)

            if (success) {
                // Обновляем отображение
                employeePhoto.source = fileUrl
                // Обновляем данные в объекте
                employeeData.photo_path = fileUrl

                console.log("Фото загружено и сохранено в БД:", fileUrl)
                showMessage("Фото успешно загружено и сохранено")
            } else {
                console.log("Ошибка сохранения фото в БД")
                showMessage("Ошибка сохранения фото")
            }
        }
    }

    // Функция удаления фото
    function removePhoto() {
        // Удаляем фото из БД
        var success = dbManager.removeEmployeePhoto(employeeData.officer_id)

        if (success) {
            // Обновляем отображение
            employeePhoto.source = ""
            // Обновляем данные в объекте
            employeeData.photo_path = ""

            console.log("Фото удалено из БД")
            showMessage("Фото удалено")
        } else {
            console.log("Ошибка удаления фото из БД")
            showMessage("Ошибка удаления фото")
        }
    }

    // Функция для получения имени файла из URL
    function getFileName(fileUrl) {
        if (!fileUrl) return ""
        var path = fileUrl.toString()
        // Убираем префикс "file://"
        if (path.startsWith("file://")) {
            path = path.substring(7)
        }
        var parts = path.split('/')
        return parts[parts.length - 1]
    }

    // Функция показа сообщений
    function showMessage(text) {
        messageText.text = text
        messagePopup.open()
    }

    Component.onCompleted: {
        console.log("Форма деталей сотрудника загружена, данные:", JSON.stringify(employeeData))
        // Загружаем фото при инициализации
        if (employeeData.photo_path) {
            employeePhoto.source = employeeData.photo_path
        }
    }
}
