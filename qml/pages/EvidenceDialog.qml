import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Карточка материала: создание, просмотр и редактирование.
 */
Dialog {
    id: root

    property int evidenceId: 0
    property var evidenceData: ({})
    property var caseOptions: []
    property bool editMode: false
    property bool createMode: false
    property bool busy: false
    property string errorMessage: ""

    signal changed()

    readonly property var typeOptions: refData.evidenceTypes()
    readonly property var statusOptions: refData.evidenceStatuses()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 0
    width: 780
    height: 640
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
                width: Math.min(720, parent.width - 32)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 12
                        color: Theme.statusBackground(root.evidenceData.current_status || "Изъято")

                        Text {
                            anchors.centerIn: parent
                            text: root.iconForType(root.evidenceData.type)
                            font.pixelSize: 22
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            width: parent.width
                            text: root.createMode
                                  ? "Новый материал"
                                  : (root.evidenceData.type || "Материал")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontHeading
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.createMode
                                  ? "Опишите предмет и привяжите его к делу"
                                  : (root.evidenceData.case_number
                                     ? "Дело № " + root.evidenceData.case_number
                                     : "Без привязки к делу")
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }

                        Badge {
                            visible: !root.createMode
                            text: root.evidenceData.current_status || ""
                            textColor: Theme.statusColor(root.evidenceData.current_status)
                            bgColor: Theme.statusBackground(root.evidenceData.current_status)
                            small: true
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
                    implicitHeight: evidenceError.implicitHeight + 20
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
                            id: evidenceError
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

                    Card {
                        Layout.fillWidth: true
                        title: "Сведения о материале"
                        icon: "📦"

                        InfoRow { label: "Тип"; value: root.evidenceData.type }
                        InfoRow { label: "Статус"; value: root.evidenceData.current_status }
                        InfoRow { label: "Дело"; value: root.evidenceData.case_number ? "№ " + root.evidenceData.case_number : "Без дела" }
                        InfoRow { label: "Зарегистрирован"; value: Theme.formatDateTime(root.evidenceData.registration_date) }
                        InfoRow { label: "Место хранения"; value: root.evidenceData.storage_location }
                        InfoRow { label: "Принял"; value: root.evidenceData.officer_name }
                    }

                    Card {
                        Layout.fillWidth: true
                        title: "Описание"
                        icon: "📝"

                        Text {
                            Layout.fillWidth: true
                            text: root.evidenceData.description || "Описание отсутствует"
                            color: root.evidenceData.description ? Theme.text : Theme.textFaint
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
                        title: "Сведения о материале"
                        icon: "📦"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            AppComboBox {
                                id: typeCombo
                                Layout.fillWidth: true
                                label: "Тип материала"
                                model: root.typeOptions
                            }

                            AppComboBox {
                                id: statusCombo
                                Layout.fillWidth: true
                                label: "Статус"
                                model: root.statusOptions
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            AppComboBox {
                                id: caseCombo
                                Layout.fillWidth: true
                                label: "Уголовное дело"
                                model: root.caseOptions
                                textRole: "label"
                                valueRole: "id"
                            }

                            DateField {
                                id: registrationDate
                                Layout.fillWidth: true
                                label: "Дата регистрации"
                            }

                            AppTextField {
                                id: storageField
                                Layout.fillWidth: true
                                label: "Место хранения"
                                placeholder: "Сейф, склад, камера хранения"
                            }
                        }

                        AppTextArea {
                            id: descriptionArea
                            Layout.fillWidth: true
                            label: "Описание"
                            required: true
                            placeholder: "Наименование, серия, номер, особые приметы"
                            preferredHeight: 140
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
                    if (root.createMode)
                        root.close()
                    else {
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
        heading: "Удалить материал?"
        message: "Запись будет удалена из реестра вещественных доказательств."
        confirmText: "Удалить"
        icon: "🗑"
        destructive: true
        onConfirmed: root.removeItem()
    }

    function iconForType(type) {
        switch (type) {
        case "Оружие": return "🔫"
        case "Транспортное средство": return "🚗"
        case "Одежда": return "👕"
        case "Биологический образец": return "🧬"
        case "Документы": return "📄"
        case "Электронный носитель": return "💾"
        default: return "📦"
        }
    }

    function loadCaseOptions() {
        var options = [{ id: 0, label: "Без дела" }]
        var cases = dbManager.getCaseOptions() || []
        for (var i = 0; i < cases.length; ++i)
            options.push(cases[i])
        root.caseOptions = options
    }

    function populate() {
        typeCombo.currentIndex = Math.max(0, root.typeOptions.indexOf(root.evidenceData.type))
        statusCombo.currentIndex = Math.max(0, root.statusOptions.indexOf(root.evidenceData.current_status))
        registrationDate.value = Theme.isoDatePart(root.evidenceData.registration_date) || Theme.todayIso()
        storageField.text = root.evidenceData.storage_location || ""
        descriptionArea.text = root.evidenceData.description || ""

        var caseId = root.evidenceData.case_id || 0
        var caseIndex = 0
        for (var i = 0; i < root.caseOptions.length; ++i) {
            if (root.caseOptions[i].id === caseId) {
                caseIndex = i
                break
            }
        }
        caseCombo.currentIndex = caseIndex
    }

    function openItem(id) {
        var data = dbManager.getEvidenceItem(id)
        if (!data || !data.ok) {
            App.notify(data && data.error ? data.error : "Не удалось открыть материал", "error")
            return
        }
        root.evidenceId = id
        root.evidenceData = data
        root.createMode = false
        root.editMode = false
        root.errorMessage = ""
        loadCaseOptions()
        populate()
        root.open()
    }

    function openCreate() {
        root.evidenceId = 0
        root.evidenceData = ({})
        root.createMode = true
        root.editMode = true
        root.errorMessage = ""
        loadCaseOptions()
        populate()
        root.open()
        descriptionArea.textArea.forceActiveFocus()
    }

    function startEdit() {
        populate()
        root.errorMessage = ""
        root.editMode = true
    }

    function save() {
        if (root.busy)
            return
        if (descriptionArea.text.trim() === "") {
            root.errorMessage = "Добавьте описание материала"
            return
        }

        var selectedCase = (root.caseOptions.length > 0 && caseCombo.currentIndex >= 0)
                           ? root.caseOptions[caseCombo.currentIndex] : { id: 0 }
        var data = {
            type: typeCombo.currentText,
            current_status: statusCombo.currentText,
            case_id: selectedCase ? selectedCase.id : 0,
            registration_date: registrationDate.value,
            storage_location: storageField.text.trim(),
            description: descriptionArea.text.trim()
        }

        root.busy = true
        var result
        if (root.createMode) {
            result = dbManager.createEvidence(data)
        } else {
            data.id = root.evidenceId
            result = dbManager.updateEvidence(data)
        }
        root.busy = false

        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось сохранить материал"
            return
        }

        App.notify(root.createMode ? "Материал добавлен" : "Материал сохранён", "success")
        root.changed()

        if (root.createMode) {
            root.close()
        } else {
            var updated = dbManager.getEvidenceItem(root.evidenceId)
            if (updated && updated.ok)
                root.evidenceData = updated
            root.editMode = false
        }
    }

    function removeItem() {
        var result = dbManager.removeEvidence(root.evidenceId)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось удалить материал"
            return
        }
        App.notify("Материал удалён", "success")
        root.changed()
        root.close()
    }
}
