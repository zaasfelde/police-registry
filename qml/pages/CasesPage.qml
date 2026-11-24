import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Список уголовных дел.
 */
Rectangle {
    id: page

    color: Theme.bg

    property var cases: []
    property var filtered: []
    property int statusFilter: 0

    readonly property var statusOptions: ["Все статусы"].concat(refData.caseStatuses())

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
        cases = dbManager.getCases() || []
        applyFilter()
    }

    function applyFilter() {
        var text = searchField.text.toLowerCase().trim()
        var status = statusFilter === 0 ? "" : statusOptions[statusFilter]

        filtered = cases.filter(function(item) {
            if (status !== "" && item.status !== status)
                return false
            if (text === "")
                return true
            var haystack = (item.case_number + " " + item.title + " " + (item.description || "")
                            + " " + (item.investigator_name || "")).toLowerCase()
            return haystack.indexOf(text) !== -1
        })
    }

    function countByStatus(status) {
        var count = 0
        for (var i = 0; i < cases.length; ++i) {
            if (cases[i].status === status)
                count++
        }
        return count
    }

    function openEntity(id) {
        caseDialog.openCase(id)
    }

    function openCreate() {
        caseDialog.openCreate()
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
                placeholderText: "Поиск по номеру, названию, следователю"
                onTextChanged: page.applyFilter()
            }

            AppComboBox {
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

            AppButton {
                text: "Добавить дело"
                icon: "＋"
                onClicked: page.openCreate()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: refData.caseStatuses()

                Rectangle {
                    Layout.preferredWidth: 170
                    height: 34
                    radius: Theme.radiusSm
                    color: Theme.statusBackground(modelData)
                    border.color: Theme.border
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: Theme.statusIcon(modelData)
                            font.pixelSize: 12
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData
                            color: Theme.statusColor(modelData)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontCaption
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            text: page.countByStatus(modelData)
                            color: Theme.statusColor(modelData)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
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
                    height: 88
                    color: rowMouse.containsMouse ? Theme.surfaceAlt : (index % 2 === 0 ? Theme.surface : "#FBFCFE")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Rectangle {
                            width: 44
                            height: 44
                            radius: 10
                            color: Theme.statusBackground(modelData.status)

                            Text {
                                anchors.centerIn: parent
                                text: Theme.statusIcon(modelData.status)
                                font.pixelSize: 18
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                width: parent.width
                                text: "Дело № " + modelData.case_number + " · " + modelData.title
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: modelData.description || "Описание отсутствует"
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: "👮 " + (modelData.investigator_name || "Следователь не назначен")
                                      + " · открыто " + Theme.formatDate(modelData.date_opened)
                                      + (modelData.date_closed ? " · закрыто " + Theme.formatDate(modelData.date_closed) : "")
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                elide: Text.ElideRight
                            }
                        }

                        Column {
                            Layout.preferredWidth: 90
                            spacing: 1

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: (modelData.persons_count || 0) + " " + Theme.plural(modelData.persons_count || 0, "лицо", "лица", "лиц")
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: (modelData.evidence_count || 0) + " " + Theme.plural(modelData.evidence_count || 0, "материал", "материала", "материалов")
                                color: Theme.textFaint
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
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
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.openEntity(modelData.case_id)
                    }
                }

                EmptyState {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    icon: "📁"
                    title: "Дела не найдены"
                    description: "Измените параметры поиска или создайте новое дело"
                    actionText: "Добавить дело"
                    onActionClicked: page.openCreate()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Показано " + page.filtered.length + " из " + page.cases.length
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "В производстве: " + (page.cases.length - page.countByStatus("Закрыто"))
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
            }
        }
    }

    CaseDialog {
        id: caseDialog
        onChanged: {
            page.reload()
            App.refresh()
        }
    }
}
