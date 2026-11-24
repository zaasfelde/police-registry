#ifndef PHOTOIMAGEPROVIDER_H
#define PHOTOIMAGEPROVIDER_H

#include <QQuickImageProvider>
#include <QString>

/*
 * Отдаёт фотографии сотрудников и личностей из каталога приложения.
 * URL: image://photo/<версия>/<имя-файла>. Версия в пути сбрасывает
 * кэш QML после замены фотографии.
 */
class PhotoImageProvider : public QQuickImageProvider
{
public:
    explicit PhotoImageProvider(const QString &directory);

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;

private:
    QString m_directory;
};

#endif // PHOTOIMAGEPROVIDER_H
