import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

Rectangle {
    id: loginForm
    anchors.fill: parent
    color: "#E0E4E9"

    signal registrationRequested()
    signal loginSuccessful()

    property color colorBackground: "#c6cdd7"
    property color colorPrimary: "#001e38"
    property color colorSecondary: "#112F49"
    property color colorAccent: "#BAC1CC"
    property color colorHover: "#557FA3"
    property color colorPressed: "#375D7F"
    property color colorTextLight: "#BAC1CC"
    property color colorTextDark: "#2c3e50"
    property color colorSrchButton: "#112F49"

    ColumnLayout {
        anchors.centerIn: parent
        width: 400
        spacing: 20

        Text {
            text: "🔐 Вход в систему"
            font.pixelSize: 28
            font.bold: true
            color: colorTextDark
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 8
            border.color: "#7d98ab"
            border.width: 1
            color: "white"

            TextField {
                id: loginField
                anchors.fill: parent
                anchors.margins: 5
                placeholderText: "Логин"
                font.pixelSize: 16
                color: "black"
                background: Rectangle {
                    color: "transparent"
                    border.width: 0
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 8
            border.color: "#7d98ab"
            border.width: 1
            color: "white"

            TextField {
                id: passwordField
                anchors.fill: parent
                anchors.margins: 5
                placeholderText: "Пароль"
                echoMode: TextInput.Password
                font.pixelSize: 16
                color: "black"
                background: Rectangle {
                    color: "transparent"
                    border.width: 0
                }
            }
        }

        Rectangle {
            id: loginBtn
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 8
            color: {
                if (loginMa.pressed) return colorPressed
                if (loginMa.containsMouse) return colorHover
                return colorSecondary
            }

            Text {
                anchors.centerIn: parent
                text: "Войти"
                color: colorTextLight
                font.pixelSize: 18
                font.bold: true
            }

            MouseArea {
                id: loginMa
                anchors.fill: parent
                hoverEnabled: true
                onClicked: login()
                cursorShape: Qt.PointingHandCursor
            }
        }

        Text {
            text: "Нет аккаунта? <a href='register'>Зарегистрироваться</a>"
            font.pixelSize: 14
            color: colorTextDark
            Layout.alignment: Qt.AlignHCenter
            linkColor: colorSecondary

            MouseArea {
                anchors.fill: parent
                onClicked: registrationRequested()
                cursorShape: Qt.PointingHandCursor
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
    }

    function login() {
        var login = loginField.text.trim()
        var password = passwordField.text.trim()

        if (!login || !password) {
            errorText.text = "Заполните все поля"
            return
        }

        // Проверяем логин и пароль через C++
        var success = dbManager.verifyLogin(login, password)

        if (success) {
            errorText.text = ""
            loginSuccessful()
        } else {
            errorText.text = "Неверный логин или пароль"
        }
    }

    function clearForm() {
        loginField.text = ""
        passwordField.text = ""
        errorText.text = ""
    }
}
