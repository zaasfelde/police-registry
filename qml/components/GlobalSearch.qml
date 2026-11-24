import QtQuick
import QtQuick.Controls
import policedep

/*
 * Глобальный поиск по реестру с выпадающими результатами.
 */
Item {
    id: root

    property var results: []
    property int total: 0

    implicitWidth: 380
    implicitHeight: 38

    SearchField {
        id: input
        anchors.fill: parent
        placeholderText: "Поиск: сотрудник, личность, дело, материал"

        onTextChanged: debounce.restart()

        Keys.onEscapePressed: {
            popup.close()
            input.text = ""
        }

        Keys.onReturnPressed: {
            if (root.results.length > 0) {
                var item = root.results[0]
                App.openEntity(item.type, item.id)
                popup.close()
                input.text = ""
            }
        }
    }

    Timer {
        id: debounce
        interval: 220
        onTriggered: root.runSearch()
    }

    Popup {
        id: popup

        parent: root
        x: 0
        y: root.height + 6
        width: Math.max(root.width, 540)
        padding: 8
        modal: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        contentItem: Column {
            spacing: 4

            ListView {
                id: resultList
                width: popup.availableWidth
                height: Math.min(contentHeight, 380)
                clip: true
                model: root.results
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: row
                    width: resultList.width
                    height: 54
                    radius: Theme.radiusSm
                    color: rowMouse.containsMouse ? Theme.surfaceAlt : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 10

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 9
                            color: Theme.infoBg
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.pixelSize: 16
                            }
                        }

                        Column {
                            width: parent.width - 140
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: modelData.title
                                color: Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontBody
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: modelData.subtitle
                                color: Theme.textMuted
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontCaption
                                elide: Text.ElideRight
                            }
                        }

                        Badge {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.typeLabel
                            textColor: Theme.textMuted
                            bgColor: Theme.neutralBg
                            small: true
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            App.openEntity(modelData.type, modelData.id)
                            popup.close()
                            input.text = ""
                        }
                    }
                }
            }

            Text {
                visible: resultList.count === 0
                width: popup.availableWidth
                height: visible ? 56 : 0
                text: "Ничего не найдено"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        background: Rectangle {
            radius: Theme.radius
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
        }
    }

    function focusSearch() {
        input.forceActiveFocus()
    }

    function search(text) {
        input.text = text
        runSearch()
    }

    function runSearch() {        var query = input.text.trim()
        if (query.length < 2) {
            root.results = []
            root.total = 0
            popup.close()
            return
        }

        var found = dbManager.searchAll(query)
        var items = []
        var groups = [
            { key: "officers", type: "officer", label: "Сотрудник", icon: "👥" },
            { key: "persons", type: "person", label: "Личность", icon: "🧍" },
            { key: "cases", type: "case", label: "Дело", icon: "📁" },
            { key: "evidence", type: "evidence", label: "Материал", icon: "📦" }
        ]

        for (var g = 0; g < groups.length; ++g) {
            var group = groups[g]
            var list = found[group.key] || []
            for (var i = 0; i < list.length; ++i) {
                var entry = list[i]
                items.push({
                    type: group.type,
                    typeLabel: group.label,
                    icon: entry.photo_url ? "🖼" : group.icon,
                    id: entry.id,
                    title: entry.title,
                    subtitle: entry.subtitle || ""
                })
            }
        }

        root.results = items
        root.total = found.total || items.length
        popup.open()
    }
}
