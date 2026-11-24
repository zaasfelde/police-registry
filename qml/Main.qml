import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts 2.15

ApplicationWindow {
    id: rootWindow
    visible: true
    width: 1200
    height: 800
    title: "Полицейский реестр - Вход в систему"

    visibility: Window.Maximized

    // Цветовая палитра
    property color colorBackground: "#c6cdd7"
    property color colorPrimary: "#001e38"
    property color colorSecondary: "#112F49"
    property color colorAccent: "#BAC1CC"
    property color colorHover: "#557FA3"
    property color colorPressed: "#375D7F"
    property color colorTextLight: "#BAC1CC"
    property color colorTextDark: "#2c3e50"
    property color colorSrchButton: "#112F49"

    // Состояния приложения
    property bool isLoggedIn: false
    property string currentView: "login" // "login", "register", "main"

    Rectangle {
        anchors.fill: parent
        color: colorBackground

        Loader {
            id: viewLoader
            anchors.fill: parent
            source: {
                if (currentView === "login") return "pages/LoginForm.qml"
                else if (currentView === "register") return "pages/RegistrationForm.qml"
                else if (currentView === "main") return "pages/MainApp.qml"
                else return "pages/LoginForm.qml"
            }

            onLoaded: {
                if (item) {
                    // Передача цветов во все формы
                    item.colorBackground = colorBackground
                    item.colorPrimary = colorPrimary
                    item.colorSecondary = colorSecondary
                    item.colorAccent = colorAccent
                    item.colorHover = colorHover
                    item.colorPressed = colorPressed
                    item.colorTextLight = colorTextLight
                    item.colorTextDark = colorTextDark
                    item.colorSrchButton = colorSrchButton

                    // Сигналы для форм аутентификации
                    if (item.loginRequested) {
                        item.loginRequested.connect(function() {
                            currentView = "login"
                            if (typeof item.clearForm === "function") {
                                item.clearForm()
                            }
                        })
                    }

                    if (item.registrationRequested) {
                        item.registrationRequested.connect(function() {
                            currentView = "register"
                            if (typeof item.clearForm === "function") {
                                item.clearForm()
                            }
                        })
                    }

                    if (item.loginSuccessful) {
                        item.loginSuccessful.connect(function() {
                            isLoggedIn = true
                            currentView = "main"
                            rootWindow.title = "Полицейский реестр"
                        })
                    }

                    if (item.registrationSuccessful) {
                        item.registrationSuccessful.connect(function() {
                            currentView = "login"
                            if (typeof item.clearForm === "function") {
                                item.clearForm()
                            }
                        })
                    }

                    // Подключаем сигнал выхода из главного приложения
                    if (item.logoutRequested) {
                        item.logoutRequested.connect(function() {
                            isLoggedIn = false
                            currentView = "login"
                            rootWindow.title = "Полицейский реестр - Вход в систему"
                        })
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        // При запуске показываем форму логина
        currentView = "login"
    }
}
