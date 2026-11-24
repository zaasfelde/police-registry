import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Список сотрудников: поиск, фильтры, подтверждение заявок и карточка.
 */
Rectangle {
    id: page

    color: Theme.bg

    property var employees: []
    property var filtered: []
    property int statusFilter: 0
    property int pendingCount: 0

    readonly property var statusOptions: [
        "Все сотрудники",
        "Только администраторы",
        "Только сотрудники",
        "Ожидают подтверждения"
    ]

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
        employees = dbManager.getOfficers() || []
        var pending = 0
        for (var i = 0; i < employees.length; ++i) {
            if (!employees[i].is_approved)
                pending++
        }
        pendingCount = pending
        applyFilter()
    }

    function applyFilter() {
        var text = searchField.text.toLowerCase().trim()
        var rankIndex = rankFilter.currentIndex
        var selectedRank = rankIndex > 0 ? rankFilter.currentText : ""

        filtered = employees.filter(function(item) {
            var haystack = (item.full_name + " " + (item.login || "") + " " + (item.rank || "")
                            + " " + (item.position || "") + " " + (item.personnel_number || "")).toLowerCase()
            if (text !== "" && haystack.indexOf(text) === -1)
                return false
            if (selectedRank !== "" && item.rank !== selectedRank)
                return false
            if (page.statusFilter === 1 && item.role !== "admin")
                return false
            if (page.statusFilter === 2 && (item.role === "admin" || !item.is_approved))
                return false
            if (page.statusFilter === 3 && item.is_approved)
                return false
            return true
        })
    }

    function openEntity(id) {
        employeeDialog.openEmployee(id)
    }

    function openCreate() {
        App.notify("Сотрудники регистрируются самостоятельно, администратор подтверждает заявку", "info")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            SearchField {
                id: searchField
                Layout.fillWidth: true
                Layout.preferredWidth: 320
                placeholderText: "Поиск по ФИО, логину, званию, должности"
                onTextChanged: page.applyFilter()
            }

            AppComboBox {
                id: rankFilter
                Layout.preferredWidth: 250
                model: ["Все звания"].concat(refData.allRanks())
                onChosen: page.applyFilter()
            }

            AppComboBox {
                id: statusFilterCombo
                Layout.preferredWidth: 210
                model: page.statusOptions
                currentIndex: page.statusFilter
                onChosen: {
                    page.statusFilter = currentIndex
                    page.applyFilter()
                }
            }

            AppButton {
                text: "Обновить"
                icon: "↻"
                variant: "secondary"
                onClicked: page.reload()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: App.isAdmin && page.pendingCount > 0 && page.statusFilter !== 3
            height: 42
            radius: Theme.radiusSm
            color: Theme.warningBg
            border.color: "#EED9AE"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: "⏳"
                    font.pixelSize: 14
                }

                Text {
                    Layout.fillWidth: true
                    text: "Новые сотрудники ожидают подтверждения: " + page.pendingCount
                    color: Theme.warning
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                }

                AppButton {
                    text: "Показать"
                    variant: "ghost"
                    small: true
                    onClicked: {
                        page.statusFilter = 3
                        statusFilterCombo.currentIndex = 3
                        page.applyFilter()
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radius
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    color: Theme.surfaceAlt

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: "Сотрудник"
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 230
                            text: "Звание и должность"
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 56
                            horizontalAlignment: Text.AlignHCenter
                            text: "Дела"
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.bold: true
                        }

                        Text {
                            Layout.preferredWidth: 150
                            horizontalAlignment: Text.AlignRight
                            text: "Статус"
                            color: Theme.textFaint
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.bold: true
                        }
                    }
                }

                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: page.filtered
                    spacing: 1

                    delegate: Rectangle {
                        id: row
                        width: list.width
                        height: 66
                        color: rowMouse.containsMouse ? Theme.surfaceAlt : (index % 2 === 0 ? Theme.surface : "#FBFCFE")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Avatar {
                                size: 40
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
                                    font.pixelSize: Theme.fontBody
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: (modelData.login || "—")
                                          + (modelData.personnel_number ? " · таб. " + modelData.personnel_number : "")
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideRight
                                }
                            }

                            Column {
                                Layout.preferredWidth: 230
                                spacing: 1

                                Text {
                                    width: parent.width
                                    text: modelData.rank
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    elide: Text.ElideRight
                                }

                                Text {
                                    width: parent.width
                                    text: modelData.position
                                    color: Theme.textMuted
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontCaption
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                Layout.preferredWidth: 56
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData.case_count || "0"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.bold: true
                            }

                            RowLayout {
                                Layout.preferredWidth: 150
                                Layout.alignment: Qt.AlignRight
                                spacing: 6

                                Badge {
                                    text: modelData.role === "admin" ? "Администратор" : "Сотрудник"
                                    textColor: modelData.role === "admin" ? Theme.primary : Theme.textMuted
                                    bgColor: modelData.role === "admin" ? Theme.infoBg : Theme.neutralBg
                                    small: true
                                }

                                Badge {
                                    visible: !modelData.is_approved
                                    text: "Ожидает"
                                    textColor: Theme.warning
                                    bgColor: Theme.warningBg
                                    small: true
                                }
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: page.openEntity(modelData.id)
                        }
                    }

                    EmptyState {
                        anchors.centerIn: parent
                        visible: list.count === 0
                        icon: "👥"
                        title: "Сотрудники не найдены"
                        description: "Измените параметры поиска или дождитесь новых заявок"
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Показано " + page.filtered.length + " из " + page.employees.length
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: page.pendingCount > 0
                text: "Ожидают подтверждения: " + page.pendingCount
                color: Theme.warning
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                font.bold: true
            }
        }
    }

    EmployeeDialog {
        id: employeeDialog
        onChanged: {
            page.reload()
            App.refresh()
        }
    }
}
