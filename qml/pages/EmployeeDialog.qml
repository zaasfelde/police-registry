import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import policedep

/*
 * Карточка сотрудника: просмотр, редактирование, фото, подтверждение
 * учётной записи и управление ролью.
 */
Dialog {
    id: root

    property int employeeId: 0
    property var employee: ({})
    property bool editMode: false
    property bool busy: false
    property string errorMessage: ""
    property var positionOptions: []

    readonly property bool canManage: App.isAdmin
    readonly property bool isSelf: root.employee && root.employee.id === App.user.id
    readonly property bool canEdit: root.canManage || root.isSelf

    signal changed()

    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape
    padding: 0
    width: 900
    height: 700
    parent: Overlay.overlay
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? Math.round((parent.height - height) / 2) : 0

    Component.onCompleted: {
        positionOptions = ["Выберите должность"].concat(refData.positions())
    }

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

                    Avatar {
                        size: 82
                        photoUrl: root.employee.photo_url || ""
                        lastName: root.employee.last_name || ""
                        firstName: root.employee.name || ""
                        patronymic: root.employee.patronymic || ""
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            width: parent.width
                            text: root.employee.full_name || "Сотрудник"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontHeading
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: (root.employee.rank || "") + (root.employee.position ? " · " + root.employee.position : "")
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                        }

                        Row {
                            spacing: 6

                            Badge {
                                text: root.employee.role === "admin" ? "Администратор" : "Сотрудник"
                                textColor: root.employee.role === "admin" ? Theme.primary : Theme.textMuted
                                bgColor: root.employee.role === "admin" ? Theme.infoBg : Theme.neutralBg
                                small: true
                            }

                            Badge {
                                visible: !!root.employee.id && !root.employee.is_approved
                                text: "Ожидает подтверждения"
                                textColor: Theme.warning
                                bgColor: Theme.warningBg
                                small: true
                            }

                            Badge {
                                text: root.employee.totp_enabled ? "2FA" : "без 2FA"
                                textColor: root.employee.totp_enabled ? Theme.success : Theme.textMuted
                                bgColor: root.employee.totp_enabled ? Theme.successBg : Theme.neutralBg
                                small: true
                            }
                        }

                        Row {
                            spacing: 6
                            topPadding: 4

                            AppButton {
                                text: root.employee.photo_url ? "Изменить фото" : "Добавить фото"
                                icon: "📷"
                                variant: "ghost"
                                small: true
                                onClicked: photoDialog.open()
                            }

                            AppButton {
                                visible: !!root.employee.photo_url
                                text: "Удалить фото"
                                variant: "ghost"
                                small: true
                                onClicked: root.removePhoto()
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
                    implicitHeight: detailError.implicitHeight + 20
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
                            id: detailError
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
                            icon: "👤"

                            InfoRow { label: "Дата рождения"; value: Theme.formatDate(root.employee.birth_date) }
                            InfoRow { label: "Возраст"; value: Theme.ageText(root.employee.age) }
                            InfoRow { label: "Телефон"; value: root.employee.phone }
                            InfoRow { label: "Электронная почта"; value: root.employee.email }
                            InfoRow { label: "Логин"; value: root.employee.login }
                        }

                        Card {
                            Layout.fillWidth: true
                            title: "Служебные данные"
                            icon: "🎖"

                            InfoRow { label: "Звание"; value: root.employee.rank }
                            InfoRow { label: "Категория"; value: root.employee.rank_category }
                            InfoRow { label: "Должность"; value: root.employee.position }
                            InfoRow { label: "Табельный номер"; value: root.employee.personnel_number }
                            InfoRow { label: "Дата приёма"; value: Theme.formatDate(root.employee.hire_date) }
                            InfoRow { label: "Стаж"; value: Theme.experienceText(root.employee.experience) }
                            InfoRow { label: "Последний вход"; value: Theme.formatDateTime(root.employee.last_login) }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        title: "Дела сотрудника"
                        subtitle: (root.employee.cases || []).length + " " + Theme.plural((root.employee.cases || []).length, "дело", "дела", "дел")
                        icon: "📁"

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Repeater {
                                model: root.employee.cases || []

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 44
                                    radius: Theme.radiusSm
                                    color: caseMouse.containsMouse ? Theme.surfaceAlt : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 10

                                        Text {
                                            Layout.fillWidth: true
                                            text: "№ " + modelData.case_number + " · " + modelData.title
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
                                        id: caseMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.close()
                                            App.openEntity("case", modelData.id)
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: (root.employee.cases || []).length === 0
                                width: parent.width
                                height: 44
                                text: "Сотрудник не назначен следователем ни по одному делу"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
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
                        title: "Личные данные"
                        icon: "👤"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            AppTextField {
                                id: editLastName
                                Layout.fillWidth: true
                                label: "Фамилия"
                                required: true
                            }

                            AppTextField {
                                id: editFirstName
                                Layout.fillWidth: true
                                label: "Имя"
                                required: true
                            }

                            AppTextField {
                                id: editPatronymic
                                Layout.fillWidth: true
                                label: "Отчество"
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            DateField {
                                id: editBirthDate
                                Layout.fillWidth: true
                                label: "Дата рождения"
                            }

                            AppTextField {
                                id: editPhone
                                Layout.fillWidth: true
                                label: "Телефон"
                                inputMethodHints: Qt.ImhDialableCharactersOnly
                            }

                            AppTextField {
                                id: editEmail
                                Layout.fillWidth: true
                                label: "Электронная почта"
                                inputMethodHints: Qt.ImhEmailCharactersOnly
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        visible: root.canManage
                        title: "Служебные данные"
                        icon: "🎖"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            AppComboBox {
                                id: editCategory
                                Layout.fillWidth: true
                                label: "Категория звания"
                                model: refData.rankCategories()
                                onChosen: root.updateRankModel()
                            }

                            AppComboBox {
                                id: editRank
                                Layout.fillWidth: true
                                label: "Специальное звание"
                                required: true
                                model: root.rankModel
                            }
                        }

                        AppComboBox {
                            id: editPosition
                            Layout.fillWidth: true
                            label: "Должность"
                            required: true
                            model: root.positionOptions
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            AppTextField {
                                id: editPersonnel
                                Layout.fillWidth: true
                                label: "Табельный номер"
                            }

                            DateField {
                                id: editHireDate
                                Layout.fillWidth: true
                                label: "Дата приёма"
                            }

                            AppTextField {
                                id: editExperience
                                Layout.fillWidth: true
                                label: "Стаж, лет"
                                validator: IntValidator { bottom: 0; top: 60 }
                                maximumLength: 2
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: !root.canManage
                        text: "Сотрудник может самостоятельно изменить только телефон и электронную почту. Служебные данные меняет администратор."
                        color: Theme.textMuted
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontCaption
                        wrapMode: Text.WordWrap
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
                visible: !root.editMode && root.canManage && !!root.employee.id && !root.employee.is_approved
                text: "Подтвердить"
                icon: "✓"
                variant: "success"
                small: true
                onClicked: root.approve()
            }

            AppButton {
                visible: !root.editMode && root.canManage && !!root.employee.id && !root.isSelf
                text: root.employee.role === "admin" ? "Снять администратора" : "Назначить администратором"
                variant: "ghost"
                small: true
                onClicked: root.toggleRole()
            }

            AppButton {
                visible: !root.editMode && root.canManage && !!root.employee.id && !root.isSelf
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
                    root.editMode = false
                    root.errorMessage = ""
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
                visible: !root.editMode && root.canEdit
                text: "Редактировать"
                icon: "✎"
                onClicked: root.startEdit()
            }
        }
    }

    property var rankModel: ["Выберите звание"]

    FileDialog {
        id: photoDialog
        title: "Фотография сотрудника"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Изображения (*.jpg *.jpeg *.png *.bmp *.webp)", "Все файлы (*)"]
        onAccepted: root.uploadPhoto(photoDialog.selectedFile)
    }

    ConfirmDialog {
        id: deleteDialog
        heading: "Удалить сотрудника?"
        message: "Учётная запись и фотография будут удалены. Дела, где сотрудник был следователем, останутся без следователя."
        confirmText: "Удалить"
        icon: "🗑"
        destructive: true
        onConfirmed: root.removeEmployee()
    }

    function updateRankModel() {
        rankModel = ["Выберите звание"].concat(refData.ranks(editCategory.currentText))
    }

    function populate() {
        if (!root.employee || !root.employee.id)
            return
        editLastName.text = root.employee.last_name || ""
        editFirstName.text = root.employee.name || ""
        editPatronymic.text = root.employee.patronymic || ""
        editBirthDate.value = root.employee.birth_date || ""
        editPhone.text = root.employee.phone || ""
        editEmail.text = root.employee.email || ""
        editPersonnel.text = root.employee.personnel_number || ""
        editHireDate.value = root.employee.hire_date || ""
        editExperience.text = String(root.employee.experience || 0)

        var categories = refData.rankCategories()
        var categoryIndex = categories.indexOf(root.employee.rank_category)
        editCategory.currentIndex = categoryIndex >= 0 ? categoryIndex : 0
        updateRankModel()
        var rankIndex = rankModel.indexOf(root.employee.rank)
        editRank.currentIndex = rankIndex >= 0 ? rankIndex : 0
        var positionIndex = positionOptions.indexOf(root.employee.position)
        editPosition.currentIndex = positionIndex >= 0 ? positionIndex : 0
    }

    function openEmployee(id) {
        var data = dbManager.getOfficer(id)
        if (!data || !data.ok) {
            App.notify(data && data.error ? data.error : "Не удалось открыть карточку сотрудника", "error")
            return
        }
        root.employeeId = id
        root.employee = data
        root.editMode = false
        root.errorMessage = ""
        populate()
        root.open()
    }

    function reloadEmployee() {
        if (root.employeeId <= 0)
            return
        var data = dbManager.getOfficer(root.employeeId)
        if (data && data.ok) {
            root.employee = data
            populate()
        }
    }

    function startEdit() {
        populate()
        root.errorMessage = ""
        root.editMode = true
    }

    function save() {
        if (root.busy)
            return
        if (editLastName.text.trim().length < 2 || editFirstName.text.trim().length < 2) {
            root.errorMessage = "Укажите фамилию и имя"
            return
        }

        var data = {
            id: root.employeeId,
            last_name: editLastName.text.trim(),
            name: editFirstName.text.trim(),
            patronymic: editPatronymic.text.trim(),
            birth_date: editBirthDate.value,
            phone: editPhone.text.trim(),
            email: editEmail.text.trim()
        }

        if (root.canManage) {
            if (editRank.currentIndex <= 0) {
                root.errorMessage = "Выберите специальное звание"
                return
            }
            if (editPosition.currentIndex <= 0) {
                root.errorMessage = "Выберите должность"
                return
            }
            data.rank_category = editCategory.currentText
            data.rank = editRank.currentText
            data.position = editPosition.currentText
            data.personnel_number = editPersonnel.text.trim()
            data.hire_date = editHireDate.value
            data.experience = parseInt(editExperience.text) || 0
        }

        root.busy = true
        var result = dbManager.updateOfficer(data)
        root.busy = false

        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось сохранить данные"
            return
        }

        root.employee = dbManager.getOfficer(root.employeeId)
        root.editMode = false
        root.errorMessage = ""
        App.notify("Данные сотрудника сохранены", "success")
        root.changed()
    }

    function uploadPhoto(url) {
        var result = dbManager.setOfficerPhoto(root.employeeId, url)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось загрузить фотографию"
            return
        }
        root.reloadEmployee()
        root.changed()
        App.notify("Фотография обновлена", "success")
    }

    function removePhoto() {
        var result = dbManager.removeOfficerPhoto(root.employeeId)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось удалить фотографию"
            return
        }
        root.reloadEmployee()
        root.changed()
        App.notify("Фотография удалена", "success")
    }

    function approve() {
        var result = dbManager.setOfficerApproval(root.employeeId, true)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось подтвердить сотрудника"
            return
        }
        root.reloadEmployee()
        root.changed()
        App.notify("Учётная запись подтверждена", "success")
    }

    function toggleRole() {
        var newRole = root.employee.role === "admin" ? "officer" : "admin"
        var result = dbManager.setOfficerRole(root.employeeId, newRole)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось изменить роль"
            return
        }
        root.reloadEmployee()
        root.changed()
        App.notify(newRole === "admin" ? "Назначен администратором" : "Права администратора сняты", "success")
    }

    function removeEmployee() {
        var result = dbManager.removeOfficer(root.employeeId)
        if (!result.ok) {
            root.errorMessage = result.error || "Не удалось удалить сотрудника"
            return
        }
        App.notify("Сотрудник удалён", "success")
        root.changed()
        root.close()
    }
}
