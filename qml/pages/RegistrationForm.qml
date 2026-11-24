import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Регистрация сотрудника: личные данные, служба и учётная запись.
 * Первый зарегистрированный пользователь становится администратором,
 * остальные ожидают подтверждения.
 */
Rectangle {
    id: page

    anchors.fill: parent
    color: Theme.bg

    signal loginRequested()
    signal registrationSuccessful()

    property bool firstUser: false
    property bool busy: false
    property string pendingPhotoUrl: ""
    property string summaryError: ""

    property string lastNameError: ""
    property string firstNameError: ""
    property string birthError: ""
    property string phoneError: ""
    property string emailError: ""
    property string rankError: ""
    property string positionError: ""
    property string loginError: ""
    property string passwordError: ""
    property string confirmError: ""

    property var rankModel: ["Выберите звание"]
    property var positionModel: ["Выберите должность"]

    Component.onCompleted: {
        firstUser = !dbManager.hasUsers()
        positionModel = ["Выберите должность"].concat(refData.positions())
        updateRankModel()
        lastNameField.forceActiveFocus()
    }

    function updateRankModel() {
        rankModel = ["Выберите звание"].concat(refData.ranks(categoryCombo.currentText))
        rankCombo.currentIndex = 0
    }

    function clearErrors() {
        lastNameError = ""
        firstNameError = ""
        birthError = ""
        phoneError = ""
        emailError = ""
        rankError = ""
        positionError = ""
        loginError = ""
        passwordError = ""
        confirmError = ""
        summaryError = ""
    }

    function ageFromIso(iso) {
        if (!iso)
            return -1
        var birth = new Date(iso + "T00:00:00")
        if (isNaN(birth.getTime()))
            return -1
        var today = new Date()
        var age = today.getFullYear() - birth.getFullYear()
        if (today.getMonth() < birth.getMonth()
                || (today.getMonth() === birth.getMonth() && today.getDate() < birth.getDate()))
            age--
        return age
    }

    function checkLoginAvailable() {
        var login = loginField.text.trim()
        if (login.length < 4) {
            loginError = ""
            return
        }
        loginError = dbManager.isLoginFree(login) ? "" : "Этот логин уже занят"
    }

    function validate() {
        clearErrors()
        var ok = true

        if (lastNameField.text.trim().length < 2) {
            lastNameError = "Укажите фамилию"
            ok = false
        }
        if (firstNameField.text.trim().length < 2) {
            firstNameError = "Укажите имя"
            ok = false
        }

        var birth = birthDateField.value
        if (birth && (ageFromIso(birth) < 18 || ageFromIso(birth) > 75)) {
            birthError = "Сотрудник должен быть старше 18 лет"
            ok = false
        }

        var phone = phoneField.text.trim()
        if (phone !== "" && phone.replace(/\D/g, "").length < 10) {
            phoneError = "Проверьте номер телефона"
            ok = false
        }

        var email = emailField.text.trim()
        if (email !== "" && !/^[^@\s]+@[^@\s]+\.[^@\s]{2,}$/.test(email)) {
            emailError = "Проверьте адрес электронной почты"
            ok = false
        }

        if (categoryCombo.currentIndex < 0) {
            rankError = "Выберите категорию звания"
            ok = false
        }
        if (rankCombo.currentIndex <= 0) {
            rankError = "Выберите специальное звание"
            ok = false
        }
        if (positionCombo.currentIndex <= 0) {
            positionError = "Выберите должность"
            ok = false
        }

        var login = loginField.text.trim()
        if (!/^[A-Za-z0-9][A-Za-z0-9._-]{3,31}$/.test(login)) {
            loginError = "4–32 символа: латинские буквы, цифры, «.», «_», «-»"
            ok = false
        } else if (!dbManager.isLoginFree(login)) {
            loginError = "Этот логин уже занят"
            ok = false
        }

        var password = passwordField.text
        if (password.length < 8) {
            passwordError = "Не менее 8 символов"
            ok = false
        } else if (!/[A-Za-zА-Яа-яЁё]/.test(password) || !/[0-9]/.test(password)) {
            passwordError = "Пароль должен содержать букву и цифру"
            ok = false
        }

        if (confirmField.text !== password) {
            confirmError = "Пароли не совпадают"
            ok = false
        }

        if (!ok)
            summaryError = "Проверьте выделенные поля"
        return ok
    }

    function submit() {
        if (page.busy || !validate())
            return

        page.busy = true
        var data = {
            last_name: lastNameField.text.trim(),
            name: firstNameField.text.trim(),
            patronymic: patronymicField.text.trim(),
            birth_date: birthDateField.value,
            phone: phoneField.text.trim(),
            email: emailField.text.trim(),
            rank_category: categoryCombo.currentText,
            rank: rankCombo.currentText,
            position: positionCombo.currentText,
            personnel_number: personnelField.text.trim(),
            hire_date: hireDateField.value,
            experience: parseInt(experienceField.text) || 0,
            login: loginField.text.trim().toLowerCase(),
            password: passwordField.text,
            photo_url: page.pendingPhotoUrl
        }

        var result = dbManager.createOfficer(data)
        page.busy = false

        if (result.ok) {
            App.notify(result.isAdmin
                       ? "Аккаунт администратора создан. Войдите в систему."
                       : "Заявка отправлена. Администратор должен подтвердить учётную запись.",
                       "success")
            page.registrationSuccessful()
            return
        }

        page.summaryError = result.error || "Не удалось зарегистрироваться"
        if (page.summaryError.indexOf("логин") !== -1)
            page.loginError = page.summaryError
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        Item {
            width: scroll.availableWidth
            height: contentColumn.implicitHeight + 48

            ColumnLayout {
                id: contentColumn
                width: Math.min(960, parent.width - 48)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 24
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    AppButton {
                        text: "← Назад"
                        variant: "ghost"
                        onClicked: page.loginRequested()
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Регистрация сотрудника"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontHeading
                            font.bold: true
                        }

                        Text {
                            text: "Заполните личные и служебные данные. Логин и пароль понадобятся для входа."
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: noticeText.implicitHeight + 24
                    radius: Theme.radiusSm
                    color: page.firstUser ? Theme.infoBg : Theme.warningBg
                    border.color: page.firstUser ? "#C9DCF8" : "#EED9AE"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        Text {
                            text: page.firstUser ? "🛡" : "⏳"
                            font.pixelSize: 18
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: noticeText
                            width: parent.width - 34
                            text: page.firstUser
                                  ? "Это первый аккаунт в системе — он получит права администратора и сможет подтверждать остальных сотрудников."
                                  : "После регистрации учётная запись будет ожидать подтверждения администратором. Войти можно будет только после подтверждения."
                            color: page.firstUser ? Theme.info : Theme.warning
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    title: "Личные данные"
                    icon: "👤"

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 18

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                AppTextField {
                                    id: lastNameField
                                    Layout.fillWidth: true
                                    label: "Фамилия"
                                    required: true
                                    placeholder: "Иванов"
                                    error: page.lastNameError
                                    onTextChanged: page.lastNameError = ""
                                }

                                AppTextField {
                                    id: firstNameField
                                    Layout.fillWidth: true
                                    label: "Имя"
                                    required: true
                                    placeholder: "Иван"
                                    error: page.firstNameError
                                    onTextChanged: page.firstNameError = ""
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                AppTextField {
                                    id: patronymicField
                                    Layout.fillWidth: true
                                    label: "Отчество"
                                    placeholder: "Иванович"
                                }

                                DateField {
                                    id: birthDateField
                                    Layout.fillWidth: true
                                    label: "Дата рождения"
                                    error: page.birthError
                                    onEdited: page.birthError = ""
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                AppTextField {
                                    id: phoneField
                                    Layout.fillWidth: true
                                    label: "Телефон"
                                    placeholder: "+7 999 123-45-67"
                                    error: page.phoneError
                                    inputMethodHints: Qt.ImhDialableCharactersOnly
                                    onTextChanged: page.phoneError = ""
                                }

                                AppTextField {
                                    id: emailField
                                    Layout.fillWidth: true
                                    label: "Электронная почта"
                                    placeholder: "ivanov@example.com"
                                    error: page.emailError
                                    inputMethodHints: Qt.ImhEmailCharactersOnly
                                    onTextChanged: page.emailError = ""
                                }
                            }
                        }

                        PhotoPicker {
                            Layout.alignment: Qt.AlignTop
                            previewWidth: 140
                            previewHeight: 178
                            photoUrl: page.pendingPhotoUrl
                            onPhotoChosen: function(url) { page.pendingPhotoUrl = url }
                            onPhotoRemoved: page.pendingPhotoUrl = ""
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    title: "Служебные данные"
                    icon: "🎖"

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 10

                        AppComboBox {
                            id: categoryCombo
                            Layout.fillWidth: true
                            label: "Категория звания"
                            model: refData.rankCategories()
                            onChosen: page.updateRankModel()
                        }

                        AppComboBox {
                            id: rankCombo
                            Layout.fillWidth: true
                            label: "Специальное звание"
                            required: true
                            model: page.rankModel
                            error: page.rankError
                            onChosen: page.rankError = ""
                        }

                        AppComboBox {
                            id: positionCombo
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            label: "Должность"
                            required: true
                            model: page.positionModel
                            error: page.positionError
                            onChosen: page.positionError = ""
                        }

                        AppTextField {
                            id: personnelField
                            Layout.fillWidth: true
                            label: "Табельный номер"
                            placeholder: "Например, 000123"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            DateField {
                                id: hireDateField
                                Layout.fillWidth: true
                                label: "Дата приёма на службу"
                            }

                            AppTextField {
                                id: experienceField
                                Layout.fillWidth: true
                                label: "Стаж, лет"
                                placeholder: "0"
                                validator: IntValidator { bottom: 0; top: 60 }
                                inputMethodHints: Qt.ImhDigitsOnly
                                maximumLength: 2
                            }
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    title: "Учётная запись"
                    subtitle: "Пароль должен содержать не менее 8 символов, букву и цифру"
                    icon: "🔐"

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        AppTextField {
                            id: loginField
                            Layout.fillWidth: true
                            label: "Логин"
                            required: true
                            placeholder: "ivanov.i"
                            error: page.loginError
                            hint: "Латиница, цифры, точка, дефис или подчёркивание"
                            onTextChanged: page.loginError = ""
                            onEditingFinished: page.checkLoginAvailable()
                        }

                        AppTextField {
                            id: passwordField
                            Layout.fillWidth: true
                            label: "Пароль"
                            required: true
                            password: true
                            placeholder: "Придумайте пароль"
                            error: page.passwordError
                            onTextChanged: page.passwordError = ""
                        }
                    }

                    PasswordStrength {
                        Layout.fillWidth: true
                        password: passwordField.text
                    }

                    AppTextField {
                        id: confirmField
                        Layout.fillWidth: true
                        label: "Повторите пароль"
                        required: true
                        password: true
                        placeholder: "Ещё раз"
                        error: page.confirmError
                        onTextChanged: page.confirmError = ""
                        onAccepted: page.submit()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    visible: page.summaryError !== ""
                    implicitHeight: summaryText.implicitHeight + 22
                    radius: Theme.radiusSm
                    color: Theme.dangerBg
                    border.color: "#F3C9C9"
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: 11
                        spacing: 8

                        Text {
                            text: "⚠"
                            color: Theme.danger
                            font.pixelSize: 14
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: summaryText
                            width: parent.width - 24
                            text: page.summaryError
                            color: Theme.danger
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: 10

                    Item { Layout.fillWidth: true }

                    AppButton {
                        text: "Отмена"
                        variant: "secondary"
                        onClicked: page.loginRequested()
                    }

                    AppButton {
                        text: "Зарегистрироваться"
                        icon: "✓"
                        loading: page.busy
                        onClicked: page.submit()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 12
                    text: "Регистрируясь, вы подтверждаете, что являетесь сотрудником органов внутренних дел и данные будут использоваться служебным порядком."
                    color: Theme.textFaint
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }
    }
}
