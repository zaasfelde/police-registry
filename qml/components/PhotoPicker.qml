import QtQuick
import QtQuick.Dialogs
import policedep

/*
 * Блок выбора фотографии: превью, выбор файла и удаление.
 * Сам файл копируется в каталог приложения на стороне C++.
 */
Column {
    id: root

    property string photoUrl: ""
    property string label: "Фотография"
    property int previewWidth: 150
    property int previewHeight: 190
    property string hint: "JPG, PNG или WEBP, до 15 МБ"

    signal photoChosen(string url)
    signal photoRemoved()

    spacing: 8

    Text {
        text: root.label
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSmall
        font.bold: true
    }

    Rectangle {
        width: root.previewWidth
        height: root.previewHeight
        radius: Theme.radiusSm
        color: Theme.surfaceMuted
        border.color: Theme.border
        border.width: 1
        clip: true

        Image {
            id: preview
            anchors.fill: parent
            source: root.photoUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            visible: root.photoUrl !== "" && preview.status !== Image.Error
        }

        Column {
            visible: !preview.visible
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "👤"
                font.pixelSize: 34
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: "Нет фотографии"
                color: Theme.textFaint
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontCaption
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Row {
        spacing: 8

        AppButton {
            text: "Выбрать фото"
            icon: "📷"
            variant: "secondary"
            small: true
            onClicked: fileDialog.open()
        }

        AppButton {
            text: "Удалить"
            icon: "🗑"
            variant: "ghost"
            small: true
            visible: root.photoUrl !== ""
            onClicked: root.photoRemoved()
        }
    }

    Text {
        width: root.previewWidth + 90
        text: root.hint
        color: Theme.textFaint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontCaption
        wrapMode: Text.WordWrap
    }

    FileDialog {
        id: fileDialog
        title: "Выберите фотографию"
        fileMode: FileDialog.OpenFile
        nameFilters: [
            "Изображения (*.jpg *.jpeg *.png *.bmp *.webp)",
            "Все файлы (*)"
        ]
        onAccepted: root.photoChosen(fileDialog.selectedFile.toString())
    }
}
