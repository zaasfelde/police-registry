import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Главная страница: приветствие, показатели и последние записи.
 */
Rectangle {
    id: page

    color: Theme.bg

    property var stats: ({})

    Component.onCompleted: reload()

    onVisibleChanged: {
        if (visible)
            reload()
    }

    Connections {
        target: App
        function onRefreshTokenChanged() {
            if (page.visible)
                page.reload()
        }
    }

    function reload() {
        stats = dbManager.getDashboardStats()
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        Item {
            width: scroll.availableWidth
            height: content.implicitHeight + 48

            ColumnLayout {
                id: content
                width: Math.min(1240, parent.width - 48)
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 22
                spacing: 16

                // Приветствие
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 132
                    radius: Theme.radiusLg
                    color: Theme.sidebar
                    clip: true

                    Rectangle {
                        width: 240
                        height: 240
                        radius: 120
                        color: "#12304F"
                        x: parent.width - 140
                        y: -100
                    }

                    Rectangle {
                        width: 160
                        height: 160
                        radius: 80
                        color: "#0F2944"
                        x: parent.width - 260
                        y: 60
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 20

                        Column {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: Theme.greeting() + ", " + (App.user.name || "сотрудник")
                                color: "#FFFFFF"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontDisplay
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: (App.user.rank || "") + (App.user.position ? " · " + App.user.position : "")
                                color: Theme.sidebarText
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontMedium
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Text {
                                text: new Date().toLocaleDateString(Qt.locale("ru_RU"), "dddd, d MMMM yyyy")
                                color: "#7A94B0"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        RowLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignVCenter

                            AppButton {
                                text: "Добавить личность"
                                icon: "＋"
                                variant: "secondary"
                                onClicked: App.createRequested("person")
                            }

                            AppButton {
                                text: "Новое дело"
                                icon: "📁"
                                variant: "secondary"
                                onClicked: App.createRequested("case")
                            }

                            AppButton {
                                text: "Материал"
                                icon: "📦"
                                variant: "secondary"
                                onClicked: App.createRequested("evidence")
                            }
                        }
                    }
                }

                // Показатели
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 14

                    StatCard {
                        Layout.fillWidth: true
                        title: "Сотрудники"
                        value: String(page.stats.officers || 0)
                        subtitle: (page.stats.pendingOfficers || 0) > 0
                                  ? (page.stats.pendingOfficers + " ожидают подтверждения")
                                  : "Все учётные записи активны"
                        icon: "👥"
                        accent: Theme.primary
                    }

                    StatCard {
                        Layout.fillWidth: true
                        title: "Личности"
                        value: String(page.stats.persons || 0)
                        subtitle: "В картотеке отдела"
                        icon: "🧍"
                        accent: "#7C4DBE"
                    }

                    StatCard {
                        Layout.fillWidth: true
                        title: "Дела в производстве"
                        value: String(page.stats.casesOpen || 0)
                        subtitle: (page.stats.casesClosed || 0) + " закрыто всего"
                        icon: "📁"
                        accent: Theme.warning
                    }

                    StatCard {
                        Layout.fillWidth: true
                        title: "Материалы"
                        value: String(page.stats.evidence || 0)
                        subtitle: "Вещественные доказательства"
                        icon: "📦"
                        accent: Theme.success
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Card {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 760
                        title: "Последние уголовные дела"
                        subtitle: "Нажмите на строку, чтобы открыть дело"
                        icon: "📁"

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Repeater {
                                model: page.stats.recentCases || []

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 56
                                    radius: Theme.radiusSm
                                    color: caseMouse.containsMouse ? Theme.surfaceAlt : "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        spacing: 12

                                        Rectangle {
                                            width: 36
                                            height: 36
                                            radius: 9
                                            color: Theme.statusBackground(modelData.status)

                                            Text {
                                                anchors.centerIn: parent
                                                text: Theme.statusIcon(modelData.status)
                                                font.pixelSize: 15
                                            }
                                        }

                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                width: parent.width
                                                text: "№ " + modelData.case_number + " · " + modelData.title
                                                color: Theme.text
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontBody
                                                font.bold: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                width: parent.width
                                                text: (modelData.investigator_name || "Следователь не назначен")
                                                      + " · " + Theme.formatDate(modelData.date_opened)
                                                color: Theme.textMuted
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontCaption
                                                elide: Text.ElideRight
                                            }
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
                                        onClicked: App.openEntity("case", modelData.case_id)
                                    }
                                }
                            }

                            Text {
                                visible: (page.stats.recentCases || []).length === 0
                                width: parent.width
                                height: 70
                                text: "Дел пока нет — создайте первое дело"
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 330
                        Layout.fillHeight: true
                        spacing: 16

                        Card {
                            Layout.fillWidth: true
                            visible: App.isAdmin
                            title: "Требуют внимания"
                            icon: "🔔"

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: (page.stats.pendingOfficers || 0) > 0
                                          ? "Новые сотрудники ожидают подтверждения: " + page.stats.pendingOfficers
                                          : "Новых заявок нет"
                                    color: (page.stats.pendingOfficers || 0) > 0 ? Theme.warning : Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    wrapMode: Text.WordWrap
                                }

                                AppButton {
                                    Layout.fillWidth: true
                                    text: "Перейти к сотрудникам"
                                    variant: "secondary"
                                    small: true
                                    onClicked: App.navigate("employees")
                                }
                            }
                        }

                        Card {
                            Layout.fillWidth: true
                            title: "Безопасность"
                            icon: "🔐"

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Badge {
                                        text: App.user.totp_enabled ? "2FA включена" : "2FA выключена"
                                        textColor: App.user.totp_enabled ? Theme.success : Theme.warning
                                        bgColor: App.user.totp_enabled ? Theme.successBg : Theme.warningBg
                                        small: true
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: App.user.totp_enabled
                                          ? "Вход защищён одноразовыми кодами. Резервных кодов осталось: " + (App.user.recovery_codes_left || 0)
                                          : "Включите двухфакторную аутентификацию, чтобы защитить учётную запись."
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    wrapMode: Text.WordWrap
                                }

                                AppButton {
                                    Layout.fillWidth: true
                                    text: App.user.totp_enabled ? "Управление 2FA" : "Включить 2FA"
                                    variant: "secondary"
                                    small: true
                                    onClicked: App.navigate("profile")
                                }
                            }
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    title: "Недавно добавленные личности"
                    subtitle: "Последние записи картотеки"
                    icon: "🧍"

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        columnSpacing: 12
                        rowSpacing: 6

                        Repeater {
                            model: page.stats.recentPersons || []

                            Rectangle {
                                Layout.fillWidth: true
                                height: 58
                                radius: Theme.radiusSm
                                color: personMouse.containsMouse ? Theme.surfaceAlt : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 10

                                    Avatar {
                                        size: 34
                                        square: true
                                        photoUrl: modelData.photo_url || ""
                                        lastName: modelData.last_name || ""
                                        firstName: modelData.name || ""
                                        patronymic: modelData.patronymic || ""
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            width: parent.width
                                            text: modelData.full_name
                                            color: Theme.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSmall
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            width: parent.width
                                            text: (modelData.status || "")
                                                  + (modelData.case_number ? " · дело № " + modelData.case_number : " · без дела")
                                            color: Theme.textMuted
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontCaption
                                            elide: Text.ElideRight
                                        }
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
                                    onClicked: App.openEntity("person", modelData.id)
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.columnSpan: 2
                            visible: (page.stats.recentPersons || []).length === 0
                            height: 60
                            text: "Личностей пока нет — добавьте первую запись"
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontBody
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}
