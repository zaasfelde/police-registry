import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import policedep

/*
 * Профиль текущего сотрудника: контакты, пароль, 2FA и резервные коды.
 */
Rectangle {
    id: page

    color: Theme.bg

    signal logoutRequested()

    property string contactError: ""
    property string passwordError: ""
    property string passwordSuccess: ""
    property string twoFactorError: ""
    property string setupSecret: ""
    property string setupUri: ""
    property string setupCodeError: ""

    Component.onCompleted: syncContacts()

    Connections {
        target: App
        function onUserChanged() {
            page.syncContacts()
        }
    }

    function syncContacts() {
        phoneField.text = App.user.phone || ""
        emailField.text = App.user.email || ""
    }

    function refreshUser() {
        App.setUser(dbManager.currentUser())
        App.refresh()
    }

    function saveContacts() {
        contactError = ""
        var result = dbManager.updateOfficer({
            id: App.user.id,
            phone: phoneField.text.trim(),
            email: emailField.text.trim()
        })
        if (!result.ok) {
            contactError = result.error || "Не удалось сохранить контакты"
            return
        }
        refreshUser()
        App.notify("Контакты сохранены", "success")
    }

    function changePassword() {
        passwordError = ""
        passwordSuccess = ""
        if (newPasswordField.text !== confirmPasswordField.text) {
            passwordError = "Новые пароли не совпадают"
            return
        }
        var result = dbManager.changePassword(currentPasswordField.text, newPasswordField.text)
        if (!result.ok) {
            passwordError = result.error || "Не удалось изменить пароль"
            return
        }
        currentPasswordField.text = ""
        newPasswordField.text = ""
        confirmPasswordField.text = ""
        passwordSuccess = "Пароль изменён"
        App.notify("Пароль успешно изменён", "success")
    }

    function openTwoFactorSetup() {
        twoFactorError = ""
        setupCodeError = ""
        var result = dbManager.beginTwoFactorSetup()
        if (!result.ok) {
            twoFactorError = result.error || "Не удалось начать настройку 2FA"
            return
        }
        setupSecret = result.secretGrouped || result.secret
        setupUri = result.otpauth || ""
        setupCodeField.text = ""
        setupDialog.open()
    }

    function confirmTwoFactor() {
        setupCodeError = ""
        var result = dbManager.confirmTwoFactorSetup(setupCodeField.text)
        if (!result.ok) {
            setupCodeError = result.error || "Неверный код"
            return
        }
        setupDialog.close()
        refreshUser()
        recoveryDialog.showCodes(result.recoveryCodes || [])
        App.notify("Двухфакторная аутентификация включена", "success")
    }

    function openDisableDialog() {
        twoFactorError = ""
        disablePassword.text = ""
        disableCode.text = ""
        disableDialog.open()
    }

    function disableTwoFactor() {
        twoFactorError = ""
        var result = dbManager.disableTwoFactor(disablePassword.text, disableCode.text)
        if (!result.ok) {
            twoFactorError = result.error || "Не удалось отключить 2FA"
            return
        }
        disableDialog.close()
        refreshUser()
        App.notify("Двухфакторная аутентификация отключена", "warning")
    }

    function regenerateCodes() {
        var result = dbManager.regenerateRecoveryCodes()
        if (!result.ok) {
            App.notify(result.error || "Не удалось создать коды", "error")
            return
        }
        refreshUser()
        recoveryDialog.showCodes(result.recoveryCodes || [])
    }

    function uploadPhoto(url) {
        var result = dbManager.setOfficerPhoto(App.user.id, url)
        if (!result.ok) {
            App.notify(result.error || "Не удалось загрузить фотографию", "error")
            return
        }
        refreshUser()
        App.notify("Фотография обновлена", "success")
    }

    function removePhoto() {
        var result = dbManager.removeOfficerPhoto(App.user.id)
        if (!result.ok) {
            App.notify(result.error || "Не удалось удалить фотографию", "error")
            return
        }
        refreshUser()
        App.notify("Фотография удалена", "success")
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        Item {
            width: scroll.availableWidth
            height: contentColumn.implicitHeight + 44

            ColumnLayout {
                id: contentColumn
                width: Math.min(1160, parent.width - 44)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 22
                spacing: 16

                // Шапка профиля
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 168
                    radius: Theme.radiusLg
                    color: Theme.sidebar
                    clip: true

                    Rectangle {
                        width: 260
                        height: 260
                        radius: 130
                        color: "#12304F"
                        x: parent.width - 130
                        y: -110
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        Avatar {
                            size: 96
                            photoUrl: App.user.photo_url || ""
                            lastName: App.user.last_name || ""
                            firstName: App.user.name || ""
                            patronymic: App.user.patronymic || ""
                            fillColor: Theme.sidebarActive
                            textColor: "#FFFFFF"
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                width: parent.width
                                text: App.user.full_name || "Сотрудник"
                                color: "#FFFFFF"
                                font.family: Theme.fontFamily
                                font.pixelSize: 26
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: (App.user.rank || "") + (App.user.position ? " · " + App.user.position : "")
                                color: Theme.sidebarText
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMedium
                                elide: Text.ElideRight
                            }

                            Row {
                                spacing: 6
                                topPadding: 2

                                Badge {
                                    text: App.user.role === "admin" ? "Администратор" : "Сотрудник"
                                    textColor: "#FFFFFF"
                                    bgColor: App.user.role === "admin" ? "#2A5C8F" : "#1B3D62"
                                    small: true
                                }

                                Badge {
                                    text: App.user.totp_enabled ? "2FA включена" : "2FA выключена"
                                    textColor: App.user.totp_enabled ? "#B7F0D0" : "#F6D9A8"
                                    bgColor: App.user.totp_enabled ? "#1B4A3A" : "#4A3A1E"
                                    small: true
                                }

                                Badge {
                                    text: "Логин: " + (App.user.login || "—")
                                    textColor: Theme.sidebarText
                                    bgColor: "#173451"
                                    small: true
                                }
                            }
                        }

                        Column {
                            spacing: 6
                            Layout.alignment: Qt.AlignTop

                            AppButton {
                                text: App.user.photo_url ? "Изменить фото" : "Добавить фото"
                                icon: "📷"
                                variant: "secondary"
                                small: true
                                onClicked: photoDialog.open()
                            }

                            AppButton {
                                visible: !!App.user.photo_url
                                text: "Удалить фото"
                                variant: "onDark"
                                small: true
                                onClicked: page.removePhoto()
                            }
                        }
                    }
                }

                Row {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Math.max(leftColumn.implicitHeight, rightColumn.implicitHeight)
                    spacing: 16

                    Column {
                        id: leftColumn
                        width: parent.width - 416
                        spacing: 16

                        Card {
                            width: parent.width
                            title: "Личные данные"
                            icon: "👤"

                            InfoRow { label: "Фамилия"; value: App.user.last_name }
                            InfoRow { label: "Имя"; value: App.user.name }
                            InfoRow { label: "Отчество"; value: App.user.patronymic }
                            InfoRow { label: "Дата рождения"; value: Theme.formatDate(App.user.birth_date) }
                            InfoRow { label: "Табельный номер"; value: App.user.personnel_number }
                            InfoRow { label: "Дата приёма"; value: Theme.formatDate(App.user.hire_date) }
                            InfoRow { label: "Стаж"; value: Theme.experienceText(App.user.experience) }
                        }

                        Card {
                            width: parent.width
                            title: "Контактные данные"
                            subtitle: "Телефон и почта доступны для изменения"
                            icon: "📞"

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                AppTextField {
                                    id: phoneField
                                    Layout.fillWidth: true
                                    label: "Телефон"
                                    placeholder: "+7 999 123-45-67"
                                    inputMethodHints: Qt.ImhDialableCharactersOnly
                                }

                                AppTextField {
                                    id: emailField
                                    Layout.fillWidth: true
                                    label: "Электронная почта"
                                    placeholder: "name@example.com"
                                    inputMethodHints: Qt.ImhEmailCharactersOnly
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: page.contactError !== ""
                                text: page.contactError
                                color: Theme.danger
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Item { Layout.fillWidth: true }

                                AppButton {
                                    text: "Сохранить контакты"
                                    icon: "💾"
                                    onClicked: page.saveContacts()
                                }
                            }
                        }
                    }

                    Column {
                        id: rightColumn
                        width: 400
                        spacing: 16

                        Card {
                            width: parent.width
                            title: "Смена пароля"
                            icon: "🔑"

                            AppTextField {
                                id: currentPasswordField
                                Layout.fillWidth: true
                                label: "Текущий пароль"
                                password: true
                                placeholder: "Введите текущий пароль"
                            }

                            AppTextField {
                                id: newPasswordField
                                Layout.fillWidth: true
                                label: "Новый пароль"
                                password: true
                                placeholder: "Не менее 8 символов"
                            }

                            PasswordStrength {
                                Layout.fillWidth: true
                                password: newPasswordField.text
                            }

                            AppTextField {
                                id: confirmPasswordField
                                Layout.fillWidth: true
                                label: "Повторите новый пароль"
                                password: true
                                placeholder: "Ещё раз"
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: page.passwordError !== ""
                                text: page.passwordError
                                color: Theme.danger
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: page.passwordSuccess !== ""
                                text: page.passwordSuccess
                                color: Theme.success
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                font.bold: true
                            }

                            AppButton {
                                Layout.fillWidth: true
                                text: "Изменить пароль"
                                variant: "secondary"
                                onClicked: page.changePassword()
                            }
                        }

                        Card {
                            width: parent.width
                            title: "Двухфакторная аутентификация"
                            icon: "🔐"

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Badge {
                                    text: App.user.totp_enabled ? "Включена" : "Выключена"
                                    textColor: App.user.totp_enabled ? Theme.success : Theme.warning
                                    bgColor: App.user.totp_enabled ? Theme.successBg : Theme.warningBg
                                    small: true
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    visible: App.user.totp_enabled
                                    text: "Кодов осталось: " + (App.user.recovery_codes_left || 0)
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: App.user.totp_enabled
                                      ? "При входе потребуется код из Google Authenticator или другого TOTP-приложения."
                                      : "Добавьте второй фактор: при входе потребуется код из приложения-аутентификатора."
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: page.twoFactorError !== ""
                                text: page.twoFactorError
                                color: Theme.danger
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                wrapMode: Text.WordWrap
                            }

                            AppButton {
                                Layout.fillWidth: true
                                text: App.user.totp_enabled ? "Отключить 2FA" : "Включить 2FA"
                                icon: App.user.totp_enabled ? "⏻" : "🛡"
                                variant: App.user.totp_enabled ? "secondary" : "primary"
                                onClicked: App.user.totp_enabled ? page.openDisableDialog() : page.openTwoFactorSetup()
                            }

                            AppButton {
                                Layout.fillWidth: true
                                visible: App.user.totp_enabled
                                text: "Создать новые резервные коды"
                                variant: "ghost"
                                small: true
                                onClicked: page.regenerateCodes()
                            }
                        }

                        Card {
                            width: parent.width
                            title: "Сессия"
                            icon: "🕒"

                            InfoRow { label: "Последний вход"; value: Theme.formatDateTime(App.user.last_login) }
                            InfoRow { label: "Учётная запись создана"; value: Theme.formatDateTime(App.user.created_at) }
                            InfoRow { label: "Роль"; value: App.user.role === "admin" ? "Администратор" : "Сотрудник" }
                            InfoRow { label: "Дел в производстве"; value: String(App.user.case_count || 0) }

                            AppButton {
                                Layout.fillWidth: true
                                text: "Выйти из системы"
                                variant: "ghost"
                                onClicked: page.logoutRequested()
                            }
                        }
                    }
                }
            }
        }
    }

    FileDialog {
        id: photoDialog
        title: "Фотография сотрудника"
        fileMode: FileDialog.OpenFile
        nameFilters: ["Изображения (*.jpg *.jpeg *.png *.bmp *.webp)", "Все файлы (*)"]
        onAccepted: page.uploadPhoto(photoDialog.selectedFile)
    }

    // Настройка 2FA
    Dialog {
        id: setupDialog

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        padding: 0
        width: 780
        height: 570
        parent: Overlay.overlay
        x: parent ? Math.round((parent.width - width) / 2) : 0
        y: parent ? Math.round((parent.height - height) / 2) : 0

        background: Rectangle {
            radius: Theme.radiusLg
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
        }

        contentItem: ScrollView {
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: Math.min(730, parent.width - 32)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 20
                spacing: 14

                Text {
                    Layout.fillWidth: true
                    text: "Подключение двухфакторной аутентификации"
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontTitle
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    text: "Отсканируйте QR-код в Google Authenticator (или Aegis, 1Password) и введите шестизначный код, который появится в приложении."
                    color: Theme.textMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    wrapMode: Text.WordWrap
                }

                QrPanel {
                    Layout.fillWidth: true
                    uri: page.setupUri
                    secret: page.setupSecret
                }

                AppTextField {
                    id: setupCodeField
                    Layout.fillWidth: true
                    label: "Код из приложения"
                    required: true
                    placeholder: "000000"
                    maximumLength: 6
                    inputMethodHints: Qt.ImhDigitsOnly
                    error: page.setupCodeError
                    onTextChanged: page.setupCodeError = ""
                    onAccepted: page.confirmTwoFactor()
                }
            }
        }

        footer: Item {
            implicitHeight: 56

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 8

                Item { Layout.fillWidth: true }

                AppButton {
                    text: "Отмена"
                    variant: "secondary"
                    onClicked: setupDialog.close()
                }

                AppButton {
                    text: "Включить 2FA"
                    icon: "✓"
                    onClicked: page.confirmTwoFactor()
                }
            }
        }
    }

    // Отключение 2FA
    Dialog {
        id: disableDialog

        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape
        padding: 24
        width: 460
        parent: Overlay.overlay
        x: parent ? Math.round((parent.width - width) / 2) : 0
        y: parent ? Math.round((parent.height - height) / 2) : 0

        background: Rectangle {
            radius: Theme.radiusLg
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Отключить двухфакторную аутентификацию?"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontTitle
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                text: "Подтвердите паролем и текущим кодом. После отключения вход будет защищён только паролем."
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                wrapMode: Text.WordWrap
            }

            AppTextField {
                id: disablePassword
                Layout.fillWidth: true
                label: "Пароль"
                password: true
                required: true
            }

            AppTextField {
                id: disableCode
                Layout.fillWidth: true
                label: "Код из приложения или резервный код"
                required: true
                maximumLength: 11
            }

            Text {
                Layout.fillWidth: true
                visible: page.twoFactorError !== ""
                text: page.twoFactorError
                color: Theme.danger
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                wrapMode: Text.WordWrap
            }
        }

        footer: Item {
            implicitHeight: 40

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Item { Layout.fillWidth: true }

                AppButton {
                    text: "Отмена"
                    variant: "secondary"
                    onClicked: disableDialog.close()
                }

                AppButton {
                    text: "Отключить"
                    variant: "danger"
                    onClicked: page.disableTwoFactor()
                }
            }
        }
    }

    RecoveryCodesDialog {
        id: recoveryDialog
    }
}
