import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import policedep

/*
 * Вещественные доказательства и иные материалы.
 */
Rectangle {
    id: page

    color: Theme.bg

    property var evidence: []
    property var filtered: []
    property int typeFilter: 0
    property int statusFilter: 0

    readonly property var typeOptions: ["Все типы"].concat(refData.evidenceTypes())
    readonly property var statusOptions: ["Все статусы"].concat(refData.evidenceStatuses())

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
        evidence = dbManager.getEvidence() || []
        applyFilter()
    }

    function applyFilter() {
        var text = searchField.text.toLowerCase().trim()
        var type = typeFilter === 0 ? "" : typeOptions[typeFilter]
        var status = statusFilter === 0 ? "" : statusOptions[statusFilter]

        filtered = evidence.filter(function(item) {
            if (type !== "" && item.type !== type)
                return false
            if (status !== "" && item.current_status !== status)
                return false
            if (text === "")
                return true
            var haystack = ((item.description || "") + " " + (item.type || "") + " "
                            + (item.case_number || "") + " " + (item.storage_location || "")).toLowerCase()
            return haystack.indexOf(text) !== -1
        })
    }

    function iconForType(type) {
        switch (type) {
        case "Оружие": return "🔫"
        case "Транспортное средство": return "🚗"
        case "Одежда": return "👕"
        case "Биологический образец": return "🧬"
        case "Документы": return "📄"
        case "Электронный носитель": return "💾"
        default: return "📦"
        }
    }

    function openEntity(id) {
        evidenceDialog.openItem(id)
    }

    function openCreate() {
        evidenceDialog.openCreate()
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
                Layout.preferredWidth: 300
                placeholderText: "Поиск по описанию, делу, месту хранения"
                onTextChanged: page.applyFilter()
            }

            AppComboBox {
                Layout.preferredWidth: 210
                model: page.typeOptions
                currentIndex: page.typeFilter
                onChosen: {
                    page.typeFilter = currentIndex
                    page.applyFilter()
                }
            }

            AppComboBox {
                Layout.preferredWidth: 200
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
                text: "Добавить материал"
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
                    height: 76
                    color: rowMouse.containsMouse ? Theme.surfaceAlt : (index % 2 === 0 ? Theme.surface : "#FBFCFE")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Rectangle {
                            width: 42
                            height: 42
                            radius: 10
                            color: Theme.statusBackground(modelData.current_status)

                            Text {
                                anchors.centerIn: parent
                                text: page.iconForType(modelData.type)
                                font.pixelSize: 18
                            }
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                width: parent.width
                                text: modelData.type + " · " + modelData.description
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: (modelData.case_number ? "Дело № " + modelData.case_number : "Без дела")
                                      + (modelData.storage_location ? " · " + modelData.storage_location : "")
                                      + " · " + Theme.formatDateTime(modelData.registration_date)
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                elide: Text.ElideRight
                            }
                        }

                        Badge {
                            text: modelData.current_status
                            textColor: Theme.statusColor(modelData.current_status)
                            bgColor: Theme.statusBackground(modelData.current_status)
                            small: true
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.openEntity(modelData.evidence_id)
                    }
                }

                EmptyState {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    icon: "📦"
                    title: "Материалы не найдены"
                    description: "Измените параметры поиска или добавьте материал"
                    actionText: "Добавить материал"
                    onActionClicked: page.openCreate()
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Показано " + page.filtered.length + " из " + page.evidence.length
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "На экспертизе: " + page.evidence.filter(function(e) { return e.current_status === "На экспертизе" }).length
                color: Theme.textMuted
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
            }
        }
    }

    EvidenceDialog {
        id: evidenceDialog
        onChanged: {
            page.reload()
            App.refresh()
        }
    }
}
