import QtQuick
import QtQuick.Controls
import policedep

/*
 * Корневое окно: вход, регистрация и основное приложение.
 */
ApplicationWindow {
    id: rootWindow

    visible: true
    width: 1440
    height: 900
    minimumWidth: 1100
    minimumHeight: 720
    color: Theme.bg
    title: rootWindow.currentView === "main"
           ? "Полицейский реестр"
           : "Полицейский реестр — вход в систему"

    property string currentView: "login"

    function openMain() {
        rootWindow.currentView = "main"
    }

    function logout() {
        dbManager.logout()
        App.setUser(({}))
        rootWindow.currentView = "login"
    }

    Loader {
        id: viewLoader
        anchors.fill: parent
        sourceComponent: {
            if (rootWindow.currentView === "register")
                return registrationComponent
            if (rootWindow.currentView === "main")
                return mainComponent
            return loginComponent
        }
    }

    ToastHost {
        id: toastHost
        anchors.fill: parent
    }

    Component {
        id: loginComponent

        LoginForm {
            objectName: "loginForm"
            onLoginSuccessful: rootWindow.openMain()
            onRegistrationRequested: {
                rootWindow.currentView = "register"
            }
        }
    }

    Component {
        id: registrationComponent

        RegistrationForm {
            objectName: "registrationForm"
            onLoginRequested: {
                rootWindow.currentView = "login"
            }
            onRegistrationSuccessful: {
                rootWindow.currentView = "login"
            }
        }
    }

    Component {
        id: mainComponent

        MainApp {
            onLogoutRequested: rootWindow.logout()
        }
    }
}
