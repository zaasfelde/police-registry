import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Карточка личности: создание, просмотр и редактирование.
 */
Dialog {
    id: root

    property int personId: 0
    property var person: ({})
    property bool editMode: false
    property bool createMode: false
    property bool busy: false
    property string errorMessage: ""
    property string pendingPhotoUrl: ""
    property var caseOptions: []

    signal changed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 0
    width: 820
    height: 680
    parent: Overlay.overlay
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    background: Rectangle {
        radius: Theme.radiusLg
        color: Theme.surface
        border.color: Theme.border
        border.width: 1
    }

    contentItem: Item {
        ScrollView {
            anchors.fill: parent
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: Math.min(760, parent.width - 32)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Avatar {
                        size: 72
                        square: true
                        photoUrl: root.createMode ? root.pendingPhotoUrl : (root.person.photo_url || "")
                        lastName: root.person.last_name || ""
                        firstName: root.person.name || ""
                        patronymic: root.person.patronymic || ""
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            width: parent.width
                            text: root.createMode ? "Новая личность" : (root.person.full_name || "Личность")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontHeading
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.createMode
                                  ? "Заполните данные и при необходимости привяжите дело"
                                  : (root.person.case_number
                                     ? "Дело № " + root.person.case_number + (root.person.case_title ? " · " + root.person.case_title : "")
                                     : "Дело не назначено")
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }

                        Row {
                            spacing: 6

                            Badge {
                                visible: !root.createMode
                                text: root.person.status || "Статус не указан"
                                textColor: Theme.statusColor(root.person.status)
                                bgColor: Theme.statusBackground(root.person.status)
                                small: true
                            }

                            Badge {
                                visible: !root.createMode && !!root.person.criminal_record
                                text: "Судимость"
                                textColor: Theme.danger
                                bgColor: Theme.dangerBg
                                small: true
                            }
                        }
                    }

                    AppButton {
                        text: "✕"
                        variant: "ghost"
                        small: true
                        onClicked: root.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.border
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: root.errorMessage !== ""
                    implicitHeight: personError.implicitHeight + 20
                    radius: Theme.radiusSm
                    color: Theme.dangerBg
                    border.color: "#F3C9C9"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "⚠"
                            color: Theme.danger
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: personError
                            width: parent.width - 24
                            text: root.errorMessage
                            color: Theme.danger
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // ---------- Просмотр ----------
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    visible: !root.editMode

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Card {
                            Layout.fillWidth: true
                            title: "Личные данные"
                            icon: "🧍"

                            InfoRow { label: "Дата рождения"; value: Theme.formatDate(root.person.birth_date) }
                            InfoRow { label: "Возраст"; value: Theme.ageText(root.person.age) }
                            InfoRow { label: "Телефон"; value: root.person.phone }
                            InfoRow { label: "Адрес"; value: root.person.address }
                        }

                        Card {
                            Layout.fillWidth: true
                            title: "Статус и дело"
                            icon: "📁"

                            InfoRow { label: "Статус"; value: root.person.status }
                            InfoRow { label: "Судимость"; value: root.person.criminal_record ? "Есть" : "Нет" }
                            InfoRow { label: "Дело"; value: root.person.case_number ? "№ " + root.person.case_number : "Не назначено" }
                            InfoRow { label: "Добавлено"; value: Theme.formatDateTime(root.person.created_at) }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        title: "Описание"
                        icon: "📝"

                        Text {
                            Layout.fillWidth: true
                            text: root.person.description || "Описание отсутствует"
                            color: root.person.description ? Theme.text : Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                // ---------- Редактирование ----------
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 14
                    visible: root.editMode

                    Card {
                        Layout.fillWidth: true
                        title: "Личные данные"
                        icon: "🧍"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            AppTextField {
                                id: lastNameField
                                Layout.fillWidth: true
                                label: "Фамилия"
                                required: true
                            }

                            AppTextField {
                                id: firstNameField
                                Layout.fillWidth: true
                                label: "Имя"
                                required: true
                            }

                            AppTextField {
                                id: patronymicField
                                Layout.fillWidth: true
                                label: "Отчество"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            DateField {
                                id: birthDateField
                                Layout.fillWidth: true
                                label: "Дата рождения"
                            }

                            AppTextField {
                                id: phoneField
                                Layout.fillWidth: true
                                label: "Телефон"
                                inputMethodHints: Qt.ImhDialableCharactersOnly
                            }

                            AppTextField {
                                id: addressField
                                Layout.fillWidth: true
                                label: "Адрес"
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        title: "Статус и дело"
                        icon: "⚖"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            AppComboBox {
                                id: statusCombo
                                Layout.fillWidth: true
                                label: "Статус"
                                model: refData.personStatuses()
                            }

                            AppComboBox {
                                id: caseCombo
                                Layout.fillWidth: true
                                label: "Уголовное дело"
                                model: root.caseOptions
                                textRole: "label"
                                valueRole: "id"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            CheckBox {
                                id: criminalCheck
                                text: "Имеет судимость"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                            }

                            Item { Layout.fillWidth: true }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 16

                            PhotoPicker {
                                previewWidth: 120
                                previewHeight: 150
                                photoUrl: root.createMode ? root.pendingPhotoUrl : (root.person.photo_url || "")
                                onPhotoChosen: function(url) {
                                    if (root.createMode) {
                                        root.pendingPhotoUrl = url
                                    } else {
                                        root.uploadPhoto(url)
                                    }
                                }
                                onPhotoRemoved: {
                                    if (root.createMode) {
                                        root.pendingPhotoUrl = ""
                                    } else {
                                        root.removePhoto()
                                    }
                                }
                            }

                            AppTextArea {
                                id: descriptionArea
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignTop
                                label: "Описание"
                                placeholder: "Особые приметы, обстоятельства, комментарии"
                                text: root.person.description || ""
                                preferredHeight: 150
                            }
                        }
                    }
                }
            }
        }
    }

    footer: Item {
        implicitHeight: 64

        Rectangle {
            anchors.top: parent.top
            width: parent.width
            height: 1
            color: Theme.border
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 8

            AppButton {
                visible: !root.editMode && !root.createMode
                text: "Удалить"
                icon: "🗑"
                variant: "ghost"
                small: true
                onClicked: deleteDialog.open()
            }

            Item { Layout.fillWidth: true }

            AppButton {
                visible: root.editMode
                text: "Отмена"
                variant: "secondary"
                onClicked: {
                    if (root.createMode) {
                        root.close()
                    } else {
                        root.editMode = false
                        root.errorMessage = ""
                    }
                }
            }

            AppButton {
                visible: root.editMode
                text: "Сохранить"
                icon: "💾"
                loading: root.busy
                onClicked: root.save()
            }

            AppButton {
                visible: !root.editMode
                text: "Закрыть"
                variant: "secondary"
                onClicked: root.close()
            }

            AppButton {
                visible: !root.editMode && !root.createMode
                text: "Редактировать"
                icon: "✎"
                onClicked: root.startEdit()
            }
        }
    }

    ConfirmDialog {
        id: deleteDialog
        heading: "Удалить личность?"
        message: "Запись и фотография будут удалены из картотеки. Действие нельзя отменить."
        confirmText: "Удалить"
        icon: "🗑"
        destructive: true
        onConfirmed: root.removePerson()
    }

    function loadCaseOptions() {
        var options = [{ id: 0, label: "Без дела" }]
        var cases = dbManager.getCaseOptions() || []
        for (var i = 0; i < cases.length; ++i)
            options.push(cases[i])
        root.caseOptions = options
    }

    function populate() {
        lastNameField.text = root.person.last_name || ""
        firstNameField.text = root.person.name || ""
        patronymicField.text = root.person.patronymic || ""
        birthDateField.value = root.person.birth_date || ""
        phoneField.text = root.person.phone || ""
        addressField.text = root.person.address || ""
        criminalCheck.checked = !!root.person.criminal_record
        descriptionArea.text = root.person.description || ""

        var statuses = refData.personStatuses()
        var statusIndex = statuses.indexOf(root.person.status)
        statusCombo.currentIndex = statusIndex >= 0 ? statusIndex : 0

        var caseIndex = 0
        for (var i = 0; i < root.caseOptions.length; ++i) {
            if (root.caseOptions[i].id === (root.person.case_id || 0)) {
                caseIndex = i
                break
            }
        }
        caseCombo.currentIndex = caseIndex
    }

    function openPerson(id) {
        var data = dbManager.getPerson(id)
        if (!data || !data.ok) {
            App.notify(data && data.error ? data.error : "Не удалось открыть личность", "error")
            return
        }
        root.personId = id
        root.person = data
        root.createMode = false
        root.editMode = false
        root.errorMessage = ""
        loadCaseOptions()
        populate()
        root.open()
    }

    function openCreate() {
        root.personId = 0
        root.person = ({})
        root.createMode = true
        root.editMode = true
        root.pendingPhotoUrl = ""
        root.errorMessage = ""
        loadCaseOptions()
        populate()
        root.open()
        lastNameField.forceActiveFocus()
    }

    function startEdit() {
        populate()
        root.errorMessage = ""
        root.editMode = true
    }

    function save() {
        if (root.busy)
            return
        if (lastNameField.text.trim().length < 2 || firstNameField.text.trim().length < 2) {
            root.errorMessage = "Укажите фамилию и имя личности"
            return
        }

        var selectedCase = (root.caseOptions.length > 0 && caseCombo.currentIndex >= 0)
                           ? root.caseOptions[caseCombo.currentIndex] : { id: 0 }
        var data = {
            last_name: lastNameField.text.trim(),
            name: firstNameField.text.trim(),
            patronymic: patronymicField.text.trim(),
            birth_date: birthDateField.value,
            phone: phoneField.text.trim(),
            address: addressField.text.trim(),
            status: statusCombo.currentText,
            criminal_record: criminalCheck.checked,
            case_id: selectedCase ? selectedCase.id : 0,
            description: descriptionArea.text.trim()
        }

        root.busy = true
        var result
        if (root.createMode) {
            result = dbManager.createPerson(data)
            if (result.ok && root.pendingPhotoUrl !== "")
                dbManager.setPersonPhoto(result.id, root.pendingPhotoUrl)
        } else {
            data.id = root.personId
            result = dbManager.updatePerson(data)
        }
        root.busy = false

        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось сохранить личность"
            return
        }

        App.notify(root.createMode ? "Личность добавлена" : "Данные личности сохранены", "success")
        root.changed()

        if (root.createMode) {
            root.close()
        } else {
            var updated = dbManager.getPerson(root.personId)
            if (updated && updated.ok)
                root.person = updated
            root.editMode = false
            root.pendingPhotoUrl = ""
        }
    }

    function uploadPhoto(url) {
        var result = dbManager.setPersonPhoto(root.personId, url)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось загрузить фотографию"
            return
        }
        var updated = dbManager.getPerson(root.personId)
        if (updated && updated.ok)
            root.person = updated
        root.changed()
        App.notify("Фотография обновлена", "success")
    }

    function removePhoto() {
        var result = dbManager.removePersonPhoto(root.personId)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось удалить фотографию"
            return
        }
        var updated = dbManager.getPerson(root.personId)
        if (updated && updated.ok)
            root.person = updated
        root.changed()
        App.notify("Фотография удалена", "success")
    }

    function removePerson() {
        var result = dbManager.removePerson(root.personId)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось удалить личность"
            return
        }
        App.notify("Личность удалена", "success")
        root.changed()
        root.close()
    }
}
