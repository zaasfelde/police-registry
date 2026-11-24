import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Основная оболочка приложения: боковая навигация, шапка с поиском и
 * страницы разделов.
 */
Rectangle {
    id: mainApp

    anchors.fill: parent
    color: Theme.bg

    signal logoutRequested()

    property int currentPage: 0
    property int pendingCount: 0

    readonly property var pages: [
        { key: "dashboard", title: "Главная", subtitle: "Сводка по реестру отдела", icon: "▦" },
        { key: "employees", title: "Сотрудники", subtitle: "Личный состав и учётные записи", icon: "👥" },
        { key: "persons", title: "Личности", subtitle: "Картотека граждан по делам", icon: "🧍" },
        { key: "cases", title: "Уголовные дела", subtitle: "Производство и статусы дел", icon: "📁" },
        { key: "evidence", title: "Материалы", subtitle: "Вещественные доказательства", icon: "📦" },
        { key: "profile", title: "Мой профиль", subtitle: "Личные данные и безопасность", icon: "⚙" }
    ]

    Component.onCompleted: reloadCounters()

    function reloadCounters() {
        var stats = dbManager.getDashboardStats()
        pendingCount = stats.pendingOfficers || 0
    }

    function pageIndex(key) {
        for (var i = 0; i < pages.length; ++i) {
            if (pages[i].key === key)
                return i
        }
        return 0
    }

    function openPage(key) {
        currentPage = pageIndex(key)
    }

    Connections {
        target: App

        function onRefreshTokenChanged() {
            mainApp.reloadCounters()
        }

        function onNavigate(page) {
            mainApp.openPage(page)
        }

        function onOpenEntity(entityType, entityId) {
            var page = entityType === "officer" ? "employees"
                     : entityType === "person" ? "persons"
                     : entityType === "case" ? "cases" : "evidence"
            mainApp.openPage(page)
            Qt.callLater(function() {
                if (entityType === "officer")
                    employeesPage.openEntity(entityId)
                else if (entityType === "person")
                    personsPage.openEntity(entityId)
                else if (entityType === "case")
                    casesPage.openEntity(entityId)
                else
                    evidencePage.openEntity(entityId)
            })
        }

        function onCreateRequested(entityType) {
            var page = entityType === "person" ? "persons"
                     : entityType === "case" ? "cases"
                     : entityType === "evidence" ? "evidence" : "employees"
            mainApp.openPage(page)
            Qt.callLater(function() {
                if (entityType === "person")
                    personsPage.openCreate()
                else if (entityType === "case")
                    casesPage.openCreate()
                else if (entityType === "evidence")
                    evidencePage.openCreate()
                else if (entityType === "employee")
                    employeesPage.openCreate()
            })
        }
    }

    Row {
        anchors.fill: parent

        // ---------- Боковая панель ----------
        Rectangle {
            id: sidebar
            width: 252
            height: parent.height
            color: Theme.sidebar

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    Layout.bottomMargin: 12
                    spacing: 10

                    Rectangle {
                        width: 40
                        height: 44
                        radius: 10
                        color: Theme.sidebarActive
                        border.color: Theme.gold
                        border.width: 1.5

                        Text {
                            text: "★"
                            color: Theme.gold
                            font.pixelSize: 15
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 7
                        }

                        Text {
                            text: "МВД"
                            color: Theme.gold
                            font.family: Theme.fontFamily
                            font.pixelSize: 7
                            font.bold: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "ПОЛИЦЕЙСКИЙ"
                            color: "#FFFFFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.1
                        }

                        Text {
                            text: "РЕЕСТР"
                            color: "#FFFFFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.1
                        }

                        Text {
                            text: "отдел полиции"
                            color: Theme.sidebarText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                        }
                    }
                }

                Text {
                    Layout.leftMargin: 10
                    Layout.topMargin: 4
                    text: "НАВИГАЦИЯ"
                    color: "#5F7A97"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: mainApp.pages

                        Rectangle {
                            id: navItem

                            property bool active: mainApp.currentPage === index

                            width: parent.width
                            height: 44
                            radius: Theme.radiusSm
                            color: active ? Theme.sidebarActive
                                   : navMouse.containsMouse ? Theme.sidebarHover : "transparent"

                            Rectangle {
                                visible: navItem.active
                                width: 3
                                height: 20
                                radius: 2
                                color: Theme.gold
                                anchors.left: parent.left
                                anchors.leftMargin: 1
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 10
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: navItem.active ? "#FFFFFF" : Theme.sidebarText
                                    font.pixelSize: 15
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.title
                                    color: navItem.active ? "#FFFFFF" : Theme.sidebarText
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontBody
                                    font.bold: navItem.active
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: modelData.key === "employees" && mainApp.pendingCount > 0
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: Theme.danger

                                    Text {
                                        anchors.centerIn: parent
                                        text: mainApp.pendingCount
                                        color: "#FFFFFF"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.bold: true
                                    }
                                }
                            }

                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mainApp.currentPage = index
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#1B3553"
                    Layout.bottomMargin: 6
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 66
                    radius: Theme.radiusSm
                    color: userMouse.containsMouse ? Theme.sidebarHover : "#102842"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 9

                        Avatar {
                            size: 38
                            photoUrl: App.user.photo_url || ""
                            lastName: App.user.last_name || ""
                            firstName: App.user.name || ""
                            patronymic: App.user.patronymic || ""
                            fillColor: Theme.sidebarActive
                            textColor: "#FFFFFF"
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                width: parent.width
                                text: App.user.short_name || App.user.full_name || "Сотрудник"
                                color: "#FFFFFF"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: App.isAdmin ? "Администратор" : "Сотрудник"
                                color: Theme.sidebarText
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: userMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mainApp.openPage("profile")
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: Theme.radiusSm
                    color: logoutMouse.containsMouse ? "#3A2430" : "transparent"

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "🚪"
                            font.pixelSize: 13
                        }

                        Text {
                            text: "Выйти из системы"
                            color: "#F0A7A7"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: logoutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: logoutDialog.open()
                    }
                }
            }
        }

        // ---------- Основная область ----------
        ColumnLayout {
            width: parent.width - sidebar.width
            height: parent.height
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                color: Theme.surface
                border.color: Theme.border
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 20
                    spacing: 16

                    Column {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 1

                        Text {
                            text: mainApp.pages[mainApp.currentPage].title
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontTitle
                            font.bold: true
                        }

                        Text {
                            text: mainApp.pages[mainApp.currentPage].subtitle
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                        }
                    }

                    Item { Layout.fillWidth: true }

                    GlobalSearch {
                        objectName: "globalSearch"
                        Layout.preferredWidth: Math.min(380, mainApp.width * 0.3)
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Text {
                        Layout.alignment: Qt.AlignVCenter
                        text: Qt.formatDate(new Date(), "dd.MM.yyyy")
                        color: Theme.textFaint
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        width: 1
                        height: 28
                        color: Theme.border
                    }

                    Avatar {
                        Layout.alignment: Qt.AlignVCenter
                        size: 34
                        photoUrl: App.user.photo_url || ""
                        lastName: App.user.last_name || ""
                        firstName: App.user.name || ""
                        patronymic: App.user.patronymic || ""

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mainApp.openPage("profile")
                        }
                    }
                }
            }

            StackLayout {
                id: pageStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: mainApp.currentPage

                DashboardPage {
                    id: dashboardPage
                    objectName: "dashboardPage"
                }

                EmployeesPage {
                    id: employeesPage
                    objectName: "employeesPage"
                }

                PersonsPage {
                    id: personsPage
                    objectName: "personsPage"
                }

                CasesPage {
                    id: casesPage
                    objectName: "casesPage"
                }

                EvidencePage {
                    id: evidencePage
                    objectName: "evidencePage"
                }

                ProfilePage {
                    id: profilePage
                    objectName: "profilePage"
                    onLogoutRequested: mainApp.logoutRequested()
                }
            }
        }
    }

    ConfirmDialog {
        id: logoutDialog
        heading: "Выйти из системы?"
        message: "Текущая сессия будет завершена. Для продолжения работы потребуется снова ввести логин, пароль и код 2FA."
        confirmText: "Выйти"
        icon: "🚪"
        destructive: true
        onConfirmed: mainApp.logoutRequested()
    }
}
