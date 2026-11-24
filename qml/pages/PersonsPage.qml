import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Картотека личностей.
 */
Rectangle {
    id: page

    color: Theme.bg

    property var persons: []
    property var filtered: []
    property int statusFilter: 0
    readonly property var statusOptions: ["Все статусы"].concat(refData.personStatuses())

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
        persons = dbManager.getPersons() || []
        applyFilter()
    }

    function applyFilter() {
        var text = searchField.text.toLowerCase().trim()
        var status = statusFilter === 0 ? "" : statusOptions[statusFilter]

        filtered = persons.filter(function(item) {
            if (status !== "" && item.status !== status)
                return false
            if (text === "")
                return true
            var haystack = (item.full_name + " " + (item.phone || "") + " " + (item.address || "")
                            + " " + (item.description || "") + " " + (item.case_number || "")).toLowerCase()
            return haystack.indexOf(text) !== -1
        })
    }

    function openEntity(id) {
        personDialog.openPerson(id)
    }

    function openCreate() {
        personDialog.openCreate()
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
                placeholderText: "Поиск по ФИО, телефону, адресу, описанию"
                onTextChanged: page.applyFilter()
            }

            AppComboBox {
                Layout.preferredWidth: 220
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

            AppButton {
                text: "Добавить личность"
                icon: "＋"
                onClicked: page.openCreate()
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

            ListView {
                id: list
                anchors.fill: parent
                anchors.margins: 1
                clip: true
                model: page.filtered
                spacing: 1

                delegate: Rectangle {
                    id: row
                    width: list.width
                    height: 74
                    color: rowMouse.containsMouse ? Theme.surfaceAlt : (index % 2 === 0 ? Theme.surface : "#FBFCFE")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Avatar {
                            size: 42
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
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: Theme.formatDate(modelData.birth_date)
                                      + (modelData.age >= 0 ? " · " + Theme.ageText(modelData.age) : "")
                                      + (modelData.phone ? " · " + modelData.phone : "")
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            Layout.preferredWidth: 200
                            text: modelData.address || "Адрес не указан"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.preferredWidth: 140
                            text: modelData.case_number ? "Дело № " + modelData.case_number : "Без дела"
                            color: Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            Layout.preferredWidth: 180
                            Layout.alignment: Qt.AlignRight
                            spacing: 6

                            Badge {
                                text: modelData.status || "—"
                                textColor: Theme.statusColor(modelData.status)
                                bgColor: Theme.statusBackground(modelData.status)
                                small: true
                            }

                            Badge {
                                visible: modelData.criminal_record
                                text: "Судимость"
                                textColor: Theme.danger
                                bgColor: Theme.dangerBg
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
                    icon: "🧍"
                    title: "Личности не найдены"
                    description: "Измените параметры поиска или добавьте новую запись"
                    actionText: "Добавить личность"
                    onActionClicked: page.openCreate()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Показано " + page.filtered.length + " из " + page.persons.length
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Судимость: " + page.persons.filter(function(p) { return p.criminal_record }).length
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
            }
        }
    }

    PersonDialog {
        id: personDialog
        onChanged: {
            page.reload()
            App.refresh()
        }
    }
}
