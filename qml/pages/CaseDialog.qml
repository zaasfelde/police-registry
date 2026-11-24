import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Карточка уголовного дела: создание, просмотр, редактирование и удаление.
 */
Dialog {
    id: root

    property int caseId: 0
    property var caseData: ({})
    property var relatedPersons: []
    property var relatedEvidence: []
    property var investigatorOptions: []
    property bool editMode: false
    property bool createMode: false
    property bool busy: false
    property string errorMessage: ""
    property string cascadeMessage: ""

    signal changed()

    readonly property var statusOptions: refData.caseStatuses()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 0
    width: 900
    height: 700
    parent: Overlay.overlay
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    Component.onCompleted: loadInvestigators()

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
                width: Math.min(840, parent.width - 32)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    Rectangle {
                        width: 54
                        height: 54
                        radius: 12
                        color: Theme.statusBackground(root.caseData.status || "Возбуждено")

                        Text {
                            anchors.centerIn: parent
                            text: Theme.statusIcon(root.caseData.status || "Возбуждено")
                            font.pixelSize: 22
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            width: parent.width
                            text: root.createMode
                                  ? "Новое уголовное дело"
                                  : "Дело № " + (root.caseData.case_number || "") + " · " + (root.caseData.title || "")
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontHeading
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.createMode
                                  ? "Заполните сведения о деле и назначьте следователя"
                                  : "Открыто " + Theme.formatDate(root.caseData.date_opened)
                                    + (root.caseData.investigator_name ? " · " + root.caseData.investigator_name : "")
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }

                        Badge {
                            visible: !root.createMode
                            text: root.caseData.status || ""
                            textColor: Theme.statusColor(root.caseData.status)
                            bgColor: Theme.statusBackground(root.caseData.status)
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
                    implicitHeight: caseError.implicitHeight + 20
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
                            id: caseError
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
                            title: "Сведения о деле"
                            icon: "📁"

                            InfoRow { label: "Номер дела"; value: root.caseData.case_number }
                            InfoRow { label: "Статус"; value: root.caseData.status }
                            InfoRow { label: "Возбуждено"; value: Theme.formatDate(root.caseData.date_opened) }
                            InfoRow { label: "Закрыто"; value: Theme.formatDate(root.caseData.date_closed) }
                            InfoRow { label: "Следователь"; value: root.caseData.investigator_name }
                        }

                        Card {
                            Layout.fillWidth: true
                            title: "Состав дела"
                            icon: "📊"

                            InfoRow { label: "Личности"; value: String(root.relatedPersons.length) }
                            InfoRow { label: "Материалы"; value: String(root.relatedEvidence.length) }
                            InfoRow { label: "Создано"; value: Theme.formatDateTime(root.caseData.created_at) }
                            InfoRow {
                                label: "Описание"
                                value: root.caseData.description || "Описание отсутствует"
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Card {
                            Layout.fillWidth: true
                            title: "Личности по делу"
                            icon: "🧍"

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Repeater {
                                    model: root.relatedPersons

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 44
                                        radius: Theme.radiusSm
                                        color: personMouse.containsMouse ? Theme.surfaceAlt : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.full_name
                                                color: Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSmall
                                                elide: Text.ElideRight
                                            }

                                            Badge {
                                                text: modelData.status
                                                textColor: Theme.statusColor(modelData.status)
                                                bgColor: Theme.statusBackground(modelData.status)
                                                small: true
                                            }
                                        }

                                        MouseArea {
                                            id: personMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.close()
                                                App.openEntity("person", modelData.id)
                                            }
                                        }
                                    }
                                }

                                Text {
                                    visible: root.relatedPersons.length === 0
                                    width: parent.width
                                    height: 40
                                    text: "К делу пока не привязаны личности"
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }

                        Card {
                            Layout.fillWidth: true
                            title: "Материалы по делу"
                            icon: "📦"

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Repeater {
                                    model: root.relatedEvidence

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 44
                                        radius: Theme.radiusSm
                                        color: evidenceMouse.containsMouse ? Theme.surfaceAlt : "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 8

                                            Text {
                                                Layout.fillWidth: true
                                                text: modelData.type + " · " + modelData.description
                                                color: Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontCaption
                                                elide: Text.ElideRight
                                            }

                                            Badge {
                                                text: modelData.current_status
                                                textColor: Theme.statusColor(modelData.current_status)
                                                bgColor: Theme.statusBackground(modelData.current_status)
                                                small: true
                                            }
                                        }

                                        MouseArea {
                                            id: evidenceMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.close()
                                                App.openEntity("evidence", modelData.id)
                                            }
                                        }
                                    }
                                }

                                Text {
                                    visible: root.relatedEvidence.length === 0
                                    width: parent.width
                                    height: 40
                                    text: "Материалы к делу не приобщены"
                                    color: Theme.textFaint
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
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
                        title: "Основные сведения"
                        icon: "📁"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            AppTextField {
                                id: numberField
                                Layout.fillWidth: true
                                label: "Номер дела"
                                required: true
                                placeholder: "Например, 12345"
                            }

                            AppTextField {
                                id: titleField
                                Layout.fillWidth: true
                                Layout.preferredWidth: 420
                                label: "Название"
                                required: true
                                placeholder: "Краткое описание"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            DateField {
                                id: openedDate
                                Layout.fillWidth: true
                                label: "Дата возбуждения"
                                required: true
                            }

                            AppComboBox {
                                id: statusCombo
                                Layout.fillWidth: true
                                label: "Статус"
                                model: root.statusOptions
                                onChosen: {
                                    if (statusCombo.currentText === "Закрыто" && closedDate.value === "")
                                        closedDate.value = Theme.todayIso()
                                }
                            }

                            DateField {
                                id: closedDate
                                Layout.fillWidth: true
                                visible: statusCombo.currentText === "Закрыто"
                                label: "Дата закрытия"
                                hint: "Заполняется автоматически"
                            }
                        }

                        AppComboBox {
                            id: investigatorCombo
                            Layout.fillWidth: true
                            label: "Следователь"
                            model: root.investigatorOptions
                            textRole: "label"
                            valueRole: "id"
                        }

                        AppTextArea {
                            id: descriptionArea
                            Layout.fillWidth: true
                            label: "Описание"
                            placeholder: "Обстоятельства дела, статьи, комментарии"
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
                onClicked: root.tryDelete()
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
        id: cascadeDialog
        heading: "Удалить дело вместе с материалами?"
        message: root.cascadeMessage
        confirmText: "Удалить всё"
        icon: "⚠"
        destructive: true
        onConfirmed: root.forceDelete()
    }

    function loadInvestigators() {
        var officers = dbManager.getOfficers() || []
        var options = [{ id: 0, label: "Не назначен" }]
        for (var i = 0; i < officers.length; ++i) {
            if (officers[i].is_approved) {
                options.push({
                    id: officers[i].id,
                    label: officers[i].full_name + " — " + officers[i].rank
                })
            }
        }
        investigatorOptions = options
    }

    function loadRelated() {
        if (root.caseId <= 0) {
            relatedPersons = []
            relatedEvidence = []
            return
        }
        var allPersons = dbManager.getPersons() || []
        relatedPersons = allPersons.filter(function(item) {
            return item.case_id === root.caseId
        })
        var allEvidence = dbManager.getEvidence() || []
        relatedEvidence = allEvidence.filter(function(item) {
            return item.case_id === root.caseId
        })
    }

    function populate() {
        numberField.text = root.caseData.case_number || ""
        titleField.text = root.caseData.title || ""
        descriptionArea.text = root.caseData.description || ""
        openedDate.value = root.caseData.date_opened || Theme.todayIso()
        closedDate.value = root.caseData.date_closed || ""

        var statusIndex = root.statusOptions.indexOf(root.caseData.status)
        statusCombo.currentIndex = statusIndex >= 0 ? statusIndex : 0

        var investigatorId = root.caseData.investigator_id || 0
        var investigatorIndex = 0
        for (var i = 0; i < root.investigatorOptions.length; ++i) {
            if (root.investigatorOptions[i].id === investigatorId) {
                investigatorIndex = i
                break
            }
        }
        investigatorCombo.currentIndex = investigatorIndex
    }

    function openCase(id) {
        var data = dbManager.getCase(id)
        if (!data || !data.ok) {
            App.notify(data && data.error ? data.error : "Не удалось открыть дело", "error")
            return
        }
        root.caseId = id
        root.caseData = data
        root.createMode = false
        root.editMode = false
        root.errorMessage = ""
        loadInvestigators()
        loadRelated()
        populate()
        root.open()
    }

    function openCreate() {
        root.caseId = 0
        root.caseData = ({})
        root.relatedPersons = []
        root.relatedEvidence = []
        root.createMode = true
        root.editMode = true
        root.errorMessage = ""
        loadInvestigators()
        populate()
        root.open()
        numberField.forceActiveFocus()
    }

    function startEdit() {
        populate()
        root.errorMessage = ""
        root.editMode = true
    }

    function save() {
        if (root.busy)
            return
        if (numberField.text.trim() === "" || titleField.text.trim() === "") {
            root.errorMessage = "Укажите номер и название дела"
            return
        }

        var investigator = (root.investigatorOptions.length > 0 && investigatorCombo.currentIndex >= 0)
                           ? root.investigatorOptions[investigatorCombo.currentIndex] : { id: 0 }
        var data = {
            case_number: numberField.text.trim(),
            title: titleField.text.trim(),
            description: descriptionArea.text.trim(),
            date_opened: openedDate.value,
            date_closed: statusCombo.currentText === "Закрыто" ? closedDate.value : "",
            status: statusCombo.currentText,
            investigator_id: investigator ? investigator.id : 0
        }

        root.busy = true
        var result
        if (root.createMode) {
            result = dbManager.createCase(data)
        } else {
            data.id = root.caseId
            result = dbManager.updateCase(data)
        }
        root.busy = false

        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось сохранить дело"
            return
        }

        App.notify(root.createMode ? "Дело создано" : "Дело сохранено", "success")
        root.changed()

        if (root.createMode) {
            root.close()
        } else {
            var updated = dbManager.getCase(root.caseId)
            if (updated && updated.ok)
                root.caseData = updated
            loadRelated()
            root.editMode = false
        }
    }

    function tryDelete() {
        var result = dbManager.removeCase(root.caseId, false)
        if (result.ok) {
            App.notify("Дело удалено", "success")
            root.changed()
            root.close()
            return
        }
        if (result.requiresCascade) {
            root.cascadeMessage = "К делу привязаны материалы: " + result.evidence
                                  + ". Они будут удалены. Личности (" + result.persons
                                  + ") останутся в картотеке без дела."
            cascadeDialog.open()
            return
        }
        root.errorMessage = result.error || "Не удалось удалить дело"
    }

    function forceDelete() {
        var result = dbManager.removeCase(root.caseId, true)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось удалить дело"
            return
        }
        App.notify("Дело и материалы удалены", "success")
        root.changed()
        root.close()
    }
}
