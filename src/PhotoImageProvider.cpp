#include "PhotoImageProvider.h"

#include <QFileInfo>
#include <QImage>
#include <QImageReader>
#include <QPainter>
#include <QPainterPath>

namespace {
constexpr int kMaxSide = 640;
}

PhotoImageProvider::PhotoImageProvider(const QString &directory)
    : QQuickImageProvider(QQuickImageProvider::Image)
    , m_directory(directory)
{
}

QImage PhotoImageProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    const QString fileName = QFileInfo(id).fileName();
    if (fileName.isEmpty())
        return {};

    QImageReader reader(m_directory + QLatin1Char('/') + fileName);
    reader.setAutoTransform(true);
    QImage image = reader.read();
    if (image.isNull())
        return {};

    QSize target = requestedSize.isValid() && !requestedSize.isEmpty()
                       ? requestedSize
                       : image.size();
    if (target.width() > kMaxSide || target.height() > kMaxSide)
        target.scale(kMaxSide, kMaxSide, Qt::KeepAspectRatio);

    const QImage cover = image.scaled(target, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation);
    const QRect crop((cover.width() - target.width()) / 2,
                     (cover.height() - target.height()) / 2,
                     target.width(),
                     target.height());
    const QImage cropped = cover.copy(crop);

    QImage result(target, QImage::Format_ARGB32_Premultiplied);
    result.fill(Qt::transparent);

    QPainter painter(&result);
    painter.setRenderHint(QPainter::Antialiasing, true);
    QPainterPath path;
    const qreal radius = qMin(target.width(), target.height()) * 0.24;
    path.addRoundedRect(QRectF(0, 0, target.width(), target.height()), radius, radius);
    painter.setClipPath(path);
    painter.drawImage(0, 0, cropped);
    painter.end();

    if (size)
        *size = result.size();
    return result;
}
