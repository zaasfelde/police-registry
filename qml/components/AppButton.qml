import QtQuick
import QtQuick.Controls
import policedep

/*
 * Основная кнопка приложения. Варианты:
 * primary (по умолчанию), secondary, ghost, danger, success.
 *
 * Реализована как Rectangle, чтобы не конфликтовать с финальным
 * свойством icon у Button и полностью контролировать внешний вид.
 */
Rectangle {
    id: control

    signal clicked()

    property string text: ""
    property string icon: ""
    property string variant: "primary"
    property bool small: false
    property bool loading: false

    property bool hovered: mouseArea.containsMouse
    property bool down: mouseArea.pressed
    property bool pressed: down

    readonly property color foreground: {
        if (variant === "secondary")
            return Theme.primary
        if (variant === "ghost")
            return Theme.text
        if (variant === "onDark")
            return "#FFFFFF"
        return "#FFFFFF"
    }

    implicitWidth: Math.max(small ? 84 : 108, contentRow.implicitWidth + (small ? 24 : 34))
    implicitHeight: small ? 32 : 40
    radius: Theme.radiusSm
    opacity: enabled ? 1.0 : 0.5
    activeFocusOnTab: true

    color: {
        if (!enabled)
            return Theme.surfaceMuted
        if (variant === "secondary")
            return down ? Theme.infoBg : (hovered ? Theme.surfaceAlt : Theme.surface)
        if (variant === "ghost")
            return down ? Theme.surfaceMuted : (hovered ? Theme.surfaceAlt : "transparent")
        if (variant === "onDark")
            return down ? Qt.rgba(1, 1, 1, 0.22) : (hovered ? Qt.rgba(1, 1, 1, 0.14) : "transparent")
        if (variant === "danger")
            return down ? "#B93A3A" : (hovered ? "#E15A5A" : Theme.danger)
        if (variant === "success")
            return down ? "#197F51" : (hovered ? "#25AE73" : Theme.success)
        return down ? Theme.primaryPressed : (hovered ? Theme.primaryHover : Theme.primary)
    }

    border.width: activeFocus ? 2 : (variant === "secondary" || variant === "ghost" || variant === "onDark" ? 1 : 0)
    border.color: activeFocus ? Theme.gold
                  : variant === "secondary" ? Theme.border
                  : variant === "onDark" ? Qt.rgba(1, 1, 1, 0.28) : "transparent"

    Keys.onReturnPressed: {
        if (control.enabled)
            control.clicked()
    }
    Keys.onSpacePressed: {
        if (control.enabled)
            control.clicked()
    }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: control.icon !== ""
            text: control.icon
            font.pixelSize: control.small ? 13 : 15
            color: control.foreground
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: control.text !== "" && !control.loading
            text: control.text
            color: control.foreground
            font.family: Theme.fontFamily
            font.pixelSize: control.small ? Theme.fontSmall : Theme.fontMedium
            font.bold: true
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
        }

        BusyIndicator {
            visible: control.loading
            running: control.loading
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: control.enabled && !control.loading
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            control.forceActiveFocus()
            control.clicked()
        }
    }
}
