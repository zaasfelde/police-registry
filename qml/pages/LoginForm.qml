import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Экран входа: пароль + второй фактор (TOTP или резервный код).
 */
Rectangle {
    id: page

    anchors.fill: parent
    color: Theme.bg

    signal loginSuccessful()
    signal registrationRequested()

    property int step: 1
    property string pendingName: ""
    property string errorMessage: ""
    property bool busy: false
    property bool showRecovery: false
    property int lockRemaining: 0
    property bool noUsers: false

    Component.onCompleted: {
        noUsers = !dbManager.hasUsers()
        loginField.forceActiveFocus()
    }

    Timer {
        interval: 1000
        repeat: true
        running: page.lockRemaining > 0
        onTriggered: {
            page.lockRemaining--
            if (page.lockRemaining <= 0)
                page.errorMessage = ""
            else
                page.errorMessage = "Слишком много попыток. Подождите " + page.lockRemaining + " с."
        }
    }

    Row {
        anchors.fill: parent

        // ---------- Брендовая панель ----------
        Rectangle {
            id: brandPanel
            width: page.width >= 1000 ? Math.min(600, page.width * 0.45) : 0
            height: parent.height
            color: Theme.sidebar
            clip: true
            visible: width > 0

            Rectangle {
                width: 460
                height: 460
                radius: 230
                color: "#0F2A47"
                x: -160
                y: -140
            }

            Rectangle {
                width: 320
                height: 320
                radius: 160
                color: "#123152"
                x: parent.width - 180
                y: parent.height - 220
            }

            Column {
                anchors.fill: parent
                anchors.margins: 48
                spacing: 0

                Row {
                    spacing: 14

                    Rectangle {
                        width: 54
                        height: 60
                        radius: 13
                        color: Theme.sidebarActive
                        border.color: Theme.gold
                        border.width: 2

                        Text {
                            text: "★"
                            color: Theme.gold
                            font.pixelSize: 22
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 8
                        }

                        Text {
                            text: "МВД"
                            color: Theme.gold
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 7
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: "ПОЛИЦЕЙСКИЙ РЕЕСТР"
                            color: "#FFFFFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: 20
                            font.bold: true
                            font.letterSpacing: 1.2
                        }

                        Text {
                            text: "Единая информационная система"
                            color: Theme.sidebarText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                        }
                    }
                }

                Item { width: 1; height: 64 }

                Text {
                    width: parent.width
                    text: "Учёт сотрудников,\nдел и материалов"
                    color: "#FFFFFF"
                    font.family: Theme.fontFamily
                    font.pixelSize: 32
                    font.bold: true
                    lineHeight: 1.15
                }

                Item { width: 1; height: 16 }

                Text {
                    width: Math.min(420, parent.width)
                    text: "Внутренняя система отдела полиции: картотека личностей, уголовные дела, вещественные доказательства и служебные данные сотрудников."
                    color: Theme.sidebarText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontBody
                    lineHeight: 1.4
                    wrapMode: Text.WordWrap
                }

                Item { width: 1; height: 40 }

                Column {
                    spacing: 18
                    width: parent.width

                    Repeater {
                        model: [
                            { icon: "👥", title: "Сотрудники и звания", text: "Реальные специальные звания и должности МВД" },
                            { icon: "📁", title: "Дела и материалы", text: "Связи между делами, личностями и вещдоками" },
                            { icon: "🔐", title: "Защищённый доступ", text: "PBKDF2-пароли и двухфакторная аутентификация" }
                        ]

                        Row {
                            width: parent.width
                            spacing: 13

                            Rectangle {
                                width: 38
                                height: 38
                                radius: 10
                                color: "#16395D"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.pixelSize: 17
                                }
                            }

                            Column {
                                width: parent.width - 51
                                spacing: 2
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    text: modelData.title
                                    color: "#FFFFFF"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.text
                                    color: Theme.sidebarText
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true; width: 1; height: 40 }

                Text {
                    text: "Версия " + Qt.application.version + " · Доступ только для сотрудников органов внутренних дел"
                    color: "#6F89A6"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontCaption
                    width: parent.width
                    wrapMode: Text.WordWrap
                }
            }
        }

        // ---------- Форма ----------
        ScrollView {
            id: scroll
            width: parent.width - brandPanel.width
            height: parent.height
            contentWidth: availableWidth
            clip: true

            Item {
                width: scroll.availableWidth
                height: Math.max(scroll.availableHeight, card.height + 80)

                Rectangle {
                    id: card
                    width: Math.min(430, parent.width - 40)
                    height: cardColumn.implicitHeight + 56
                    radius: Theme.radiusLg
                    color: Theme.surface
                    border.color: Theme.border
                    border.width: 1
                    anchors.centerIn: parent

                    ColumnLayout {
                        id: cardColumn
                        anchors.fill: parent
                        anchors.margins: 28
                        spacing: 14

                        Row {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 10

                            Rectangle {
                                width: 40
                                height: 44
                                radius: 11
                                color: Theme.sidebar

                                Text {
                                    text: "★"
                                    color: Theme.gold
                                    font.pixelSize: 16
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -4
                                }

                                Text {
                                    text: "МВД"
                                    color: Theme.gold
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 7
                                    font.bold: true
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 5
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: page.step === 1 ? "Вход в систему" : "Подтверждение входа"
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontHeading
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            text: page.step === 1
                                  ? "Введите служебный логин и пароль"
                                  : "Введите код из приложения-аутентификатора"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: page.noUsers
                            implicitHeight: noUsersColumn.implicitHeight + 20
                            radius: Theme.radiusSm
                            color: Theme.warningBg
                            border.color: "#EED9AE"
                            border.width: 1

                            Column {
                                id: noUsersColumn
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Text {
                                    text: "В системе ещё нет учётных записей"
                                    color: Theme.warning
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.bold: true
                                }

                                Text {
                                    text: "Первый зарегистрированный сотрудник получит права администратора."
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: page.errorMessage !== ""
                            implicitHeight: errorText.implicitHeight + 20
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
                                    font.pixelSize: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    id: errorText
                                    width: parent.width - 24
                                    text: page.errorMessage
                                    color: Theme.danger
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }

                        // Шаг 1: логин и пароль
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            visible: page.step === 1

                            AppTextField {
                                id: loginField
                                Layout.fillWidth: true
                                label: "Логин"
                                placeholder: "Например, ivanov.i"
                                required: true
                                onAccepted: passwordField.forceActiveFocus()
                            }

                            AppTextField {
                                id: passwordField
                                Layout.fillWidth: true
                                label: "Пароль"
                                placeholder: "Введите пароль"
                                required: true
                                password: true
                                onAccepted: page.submitPassword()
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: "Забыли пароль?"
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: App.notify("Обратитесь к администратору отдела для сброса пароля", "info")
                                    }
                                }
                            }

                            AppButton {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                text: "Войти"
                                icon: "→"
                                loading: page.busy
                                enabled: page.lockRemaining === 0
                                onClicked: page.submitPassword()
                            }
                        }

                        // Шаг 2: второй фактор
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 12
                            visible: page.step === 2

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: Theme.radiusSm
                                color: Theme.surfaceAlt

                                Text {
                                    anchors.centerIn: parent
                                    text: page.pendingName
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.bold: true
                                }
                            }

                            AppTextField {
                                id: codeField
                                Layout.fillWidth: true
                                label: page.showRecovery ? "Резервный код" : "Код из приложения"
                                placeholder: page.showRecovery ? "XXXXX-XXXXX" : "000000"
                                required: true
                                maximumLength: page.showRecovery ? 11 : 6
                                inputMethodHints: page.showRecovery ? Qt.ImhNoPredictiveText : Qt.ImhDigitsOnly
                                hint: page.showRecovery
                                      ? "Один из кодов, выданных при включении 2FA"
                                      : "Код обновляется каждые 30 секунд"
                                onAccepted: page.submitTwoFactor()
                            }

                            AppButton {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 44
                                text: "Подтвердить"
                                loading: page.busy
                                onClicked: page.submitTwoFactor()
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: "← Другой аккаунт"
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            dbManager.cancelTwoFactor()
                                            page.step = 1
                                            page.errorMessage = ""
                                            page.showRecovery = false
                                            loginField.forceActiveFocus()
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: page.showRecovery ? "Код из приложения" : "Резервный код"
                                    color: Theme.primary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            page.showRecovery = !page.showRecovery
                                            codeField.text = ""
                                            codeField.forceActiveFocus()
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            color: Theme.border
                        }

                        AppButton {
                            Layout.fillWidth: true
                            text: "Создать учётную запись"
                            variant: "secondary"
                            onClicked: page.registrationRequested()
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Пароль хранится в виде PBKDF2-хэша. Доступ к системе журналируется."
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
    }

    function submitPassword() {
        if (page.busy || page.lockRemaining > 0)
            return
        page.errorMessage = ""
        if (loginField.text.trim() === "" || passwordField.text === "") {
            page.errorMessage = "Введите логин и пароль"
            return
        }

        page.busy = true
        var result = dbManager.authenticate(loginField.text, passwordField.text)
        page.busy = false

        if (result.ok) {
            if (result.requires2fa) {
                page.pendingName = result.displayName || ""
                page.step = 2
                page.errorMessage = ""
                codeField.text = ""
                codeField.forceActiveFocus()
                return
            }
            App.setUser(result.user)
            App.refresh()
            passwordField.text = ""
            page.loginSuccessful()
            return
        }

        page.errorMessage = result.error || "Не удалось выполнить вход"
        if (result.errorCode === "locked" && result.retryAfter)
            page.lockRemaining = result.retryAfter
        else if (result.attemptsLeft !== undefined)
            page.errorMessage += " Осталось попыток: " + result.attemptsLeft
    }

    function submitTwoFactor() {
        if (page.busy)
            return
        page.errorMessage = ""
        if (codeField.text.trim() === "") {
            page.errorMessage = page.showRecovery ? "Введите резервный код" : "Введите код из приложения"
            return
        }

        page.busy = true
        var result = dbManager.verifyTwoFactor(codeField.text)
        page.busy = false

        if (result.ok) {
            App.setUser(result.user)
            App.refresh()
            codeField.text = ""
            page.step = 1
            page.loginSuccessful()
            return
        }

        page.errorMessage = result.error || "Неверный код"
        if (result.attemptsLeft !== undefined)
            page.errorMessage += " Осталось попыток: " + result.attemptsLeft
        else {
            page.step = 1
            page.showRecovery = false
        }
    }
}
