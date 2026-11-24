import QtQuick
import QtQuick.Controls
import policedep

/*
 * ComboBox в стиле приложения: подпись, ошибка, кастомный список.
 */
Column {
    id: root

    property string label: ""
    property bool required: false
    property string error: ""
    property string hint: ""
    property alias model: control.model
    property alias textRole: control.textRole
    property alias valueRole: control.valueRole
    property alias currentIndex: control.currentIndex
    readonly property string currentText: control.currentText
    readonly property var currentValue: control.currentValue

    signal chosen()

    spacing: 6
    width: 220

    readonly property bool hasError: error !== ""

    Text {
        visible: root.label !== ""
        width: parent.width
        text: root.label + (root.required ? " *" : "")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.bold: true
        elide: Text.ElideRight
    }

    ComboBox {
        id: control
        width: root.width
        height: 40
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontMedium
        hoverEnabled: true

        contentItem: Text {
            leftPadding: 12
            rightPadding: 30
            text: control.displayText
            color: control.enabled ? Theme.text : Theme.textFaint
            font: control.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        indicator: Text {
            x: control.width - width - 12
            y: control.topPadding + (control.availableHeight - height) / 2
            text: "▾"
            color: Theme.textMuted
            font.pixelSize: 14
        }

        background: Rectangle {
            radius: Theme.radiusSm
            color: control.enabled ? Theme.surface : Theme.surfaceAlt
            border.width: control.activeFocus || root.hasError ? 2 : 1
            border.color: root.hasError ? Theme.danger : (control.activeFocus ? Theme.primary : Theme.border)
        }

        delegate: ItemDelegate {
            id: item
            width: control.width
            height: 36
            highlighted: control.highlightedIndex === index

            contentItem: Text {
                leftPadding: 10
                rightPadding: 10
                text: {
                    if (control.textRole !== "" && modelData !== null && typeof modelData === "object")
                        return modelData[control.textRole] !== undefined ? modelData[control.textRole] : ""
                    if (modelData !== null && typeof modelData === "object")
                        return modelData.label !== undefined ? modelData.label : ""
                    return modelData !== undefined && modelData !== null ? String(modelData) : ""
                }
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontBody
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
            }

            background: Rectangle {
                radius: Theme.radiusSm
                color: item.highlighted ? Theme.infoBg : (item.hovered ? Theme.surfaceAlt : "transparent")
            }
        }

        popup: Popup {
            y: control.height + 4
            width: control.width
            implicitHeight: Math.min(contentItem.implicitHeight + 12, 300)
            padding: 6
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: control.delegateModel
                currentIndex: control.highlightedIndex
                boundsBehavior: Flickable.StopAtBounds
                ScrollIndicator.vertical: ScrollIndicator { }
            }

            background: Rectangle {
                radius: Theme.radiusSm
                color: Theme.surface
                border.color: Theme.border
                border.width: 1
            }
        }

        onActivated: root.chosen()
    }

    Text {
        visible: root.hasError || root.hint !== ""
        width: parent.width
        text: root.hasError ? root.error : root.hint
        color: root.hasError ? Theme.danger : Theme.textFaint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
    }

    function indexOfValue(value) {
        return control.indexOfValue(value)
    }

    function selectValue(value) {
        var index = control.indexOfValue(value)
        if (index >= 0)
            control.currentIndex = index
        return index
    }
}
