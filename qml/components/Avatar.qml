import QtQuick
import policedep

/*
 * Аватар: фотография из локального кэша приложения или инициалы.
 */
Item {
    id: root

    property string photoUrl: ""
    property string lastName: ""
    property string firstName: ""
    property string patronymic: ""
    property int size: 40
    property bool square: false
    property color fillColor: Theme.infoBg
    property color textColor: Theme.primary

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: Math.max(8, Math.round(Math.min(width, height) * 0.24))
        color: root.fillColor
        border.color: Theme.border
        border.width: 1
        clip: true

        Image {
            id: image
            anchors.fill: parent
            source: root.photoUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            visible: root.photoUrl !== "" && image.status !== Image.Error
        }

        Text {
            visible: !image.visible
            anchors.centerIn: parent
            text: Theme.initials(root.lastName, root.firstName, root.patronymic)
            color: root.textColor
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(11, Math.round(root.size * 0.36))
            font.bold: true
        }
    }
}
